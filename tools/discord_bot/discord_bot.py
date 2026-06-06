"""Legendary Hunter Discord bot — webhook-based, polled, idempotent.

Run this script every 5 minutes via Task Scheduler. It reads the live
DB, diffs current state against the last snapshot, and posts events
(rank-ups, capstones, weekly sweeps) to Discord. Daily and weekly
digests fire on their own cadence based on the last-digest timestamps.

No bot token, no permissions, no daemon — just a webhook POST. The
first run silently bootstraps state without posting any historical
events, so existing veterans don't trigger a flood of notifications.

USAGE:
    cp tools/discord_bot/config.example.py tools/discord_bot/config.py
    # edit config.py, paste your Discord webhook URL
    python tools/discord_bot/discord_bot.py

EXIT CODES:
    0  Success (events posted or no-op)
    1  Config error (missing config.py or unfilled WEBHOOK_URL)
    2  DB unreachable
    3  Discord webhook error (URL invalid, rate limit, etc.)

Schedule example (Windows Task Scheduler, run every 5 minutes):
    Program: python.exe
    Arguments: D:\\server\\tools\\discord_bot\\discord_bot.py
    Start in: D:\\server
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
import time
import urllib.request
import urllib.error
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

# DB connection helper. The bot ships its own sibling _db.py (see that file
# for the why): the live server checkout where the bot runs does NOT contain
# the docs branch's tools/docgen/ package, so `from tools.docgen._db` raises
# ModuleNotFoundError there. Prefer the local sibling copy; fall back to the
# docgen helper only when running from inside a docs worktree.
THIS_DIR  = Path(__file__).resolve().parent
REPO_ROOT = THIS_DIR.parents[1]
sys.path.insert(0, str(REPO_ROOT))   # so tools.docgen.* resolves in a worktree
sys.path.insert(0, str(THIS_DIR))    # so the sibling _db.py wins the import

# Best-effort heartbeat (dead-man's-switch). REPO_ROOT is on sys.path and
# tools/ is a package, so tools._heartbeat resolves on the live checkout.
# Degrade to a no-op if it's ever absent — a missing heartbeat just reads as
# STALE on the status page, which is the safe direction to fail.
try:
    from tools._heartbeat import write_heartbeat
except Exception:
    def write_heartbeat(*_a, **_k):
        return False

try:
    from _db import connect  # local sibling copy (live bot checkout)  # noqa: E402
except Exception:  # pragma: no cover - only hit in a worktree lacking _db.py
    from tools.docgen._db import connect  # noqa: E402


# ============================================================
# Config loading
# ============================================================

def load_config():
    """Load config.py from this directory. Bails with code 1 if missing
    or if the user hasn't filled in WEBHOOK_URL yet — easier to spot
    than a cryptic HTTP error from Discord."""
    cfg_path = THIS_DIR / "config.py"
    if not cfg_path.exists():
        print(f"[discord_bot] config.py not found. Copy config.example.py -> config.py and set WEBHOOK_URL.")
        sys.exit(1)
    spec = {}
    exec(cfg_path.read_text(encoding="utf-8"), spec, spec)  # nosec - user-owned file
    if not spec.get("WEBHOOK_URL") or "REPLACE_ME" in spec.get("WEBHOOK_URL", ""):
        print("[discord_bot] WEBHOOK_URL is not set in config.py. Fill it in first.")
        sys.exit(1)
    return spec


# ============================================================
# State (last-seen snapshot per player + last-digest timestamps)
# ============================================================

STATE_PATH = THIS_DIR / "state.json"


def load_state():
    if not STATE_PATH.exists():
        return {"last_seen": {}, "last_digest": {}, "bootstrapped": False}
    try:
        return json.loads(STATE_PATH.read_text(encoding="utf-8"))
    except Exception as e:
        print(f"[discord_bot] state.json corrupt, starting fresh: {e}")
        return {"last_seen": {}, "last_digest": {}, "bootstrapped": False}


def save_state(state):
    """Atomic write to avoid corrupting state.json on interrupted runs."""
    tmp = STATE_PATH.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(state, indent=2, sort_keys=True), encoding="utf-8")
    os.replace(tmp, STATE_PATH)


# ============================================================
# Catalog (single source of truth)
# ============================================================
# Guild names, the rank ladder, dungeon ids/labels and broadcast
# achievements all used to be hand-copied here and inevitably drifted from
# the Lua catalogs (wrong guild label, a missing dungeon, missing Infamy
# achievements). They now come from catalog.json — exported from the live
# Lua catalogs by tools/docgen/generators/catalog_json.py and dropped next
# to this file by refresh-site.bat.
#
# The hardcoded fallbacks below are used ONLY when catalog.json is absent,
# so the bot still runs cold. When the JSON is present it is authoritative.
# To change this data, edit the Lua catalog and re-run refresh-site.

CATALOG_PATH = THIS_DIR / "catalog.json"


def load_catalog():
    """Return the parsed catalog.json dict, or None if missing/unreadable.
    None makes every derived table fall back to its hardcoded default so the
    bot degrades cleanly instead of crashing."""
    try:
        return json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    except FileNotFoundError:
        print(f"[discord_bot] catalog.json not found at {CATALOG_PATH}; using built-in fallbacks")
        return None
    except Exception as e:
        print(f"[discord_bot] catalog.json unreadable ({e}); using built-in fallbacks")
        return None


_CATALOG = load_catalog()


# --- Hunter's Guild rank ladder -------------------------------------------
_FALLBACK_RANKS = [
    {"minRep": 0,      "label": "Apprentice",  "amplifier": 0.00},
    {"minRep": 500,    "label": "Journeyman",  "amplifier": 0.10},
    {"minRep": 5000,   "label": "Veteran",     "amplifier": 0.25},
    {"minRep": 25000,  "label": "Master",      "amplifier": 0.50},
    {"minRep": 100000, "label": "Grandmaster", "amplifier": 1.00},
]
_ranks = sorted(
    (_CATALOG.get("guild_ranks") if _CATALOG else None) or _FALLBACK_RANKS,
    key=lambda r: r.get("minRep", 0),
)
RANK_THRESHOLDS = [(int(r["minRep"]), r["label"]) for r in _ranks]
RANK_LABELS  = [t[1] for t in RANK_THRESHOLDS]
RANK_AMP_PCT = [int(round(r.get("amplifier", 0) * 100)) for r in _ranks]


def rank_index_for_rep(rep: int) -> int:
    """Map a rep value to a rank index (1..5). Walks top-down so the
    highest threshold met wins."""
    for i in range(len(RANK_THRESHOLDS) - 1, -1, -1):
        if rep >= RANK_THRESHOLDS[i][0]:
            return i + 1
    return 1


# --- The four Hunter's Guilds ---------------------------------------------
_FALLBACK_GUILDS = [
    {"key": "af",    "label": "AF Hunters' Guild",       "repCv": "Guild_AF_Rep",    "markType": "AF Marks"},
    {"key": "relic", "label": "Relic Hunters' Guild",    "repCv": "Guild_Relic_Rep", "markType": "Relic Marks"},
    {"key": "empy",  "label": "Empyrean Hunters' Guild", "repCv": "Guild_Empy_Rep",  "markType": "Empy Marks"},
    {"key": "hl",    "label": "League Hunters' Guild",   "repCv": "Guild_HL_Rep",    "markType": "Hunt Marks"},
]
_guilds = (_CATALOG.get("guilds") if _CATALOG else None) or _FALLBACK_GUILDS
GUILDS = [(g["key"], g["label"], g["repCv"]) for g in _guilds]
GUILD_LABELS = {g["key"]: g["label"] for g in _guilds}
GUILD_MARK_TYPES = {g["key"]: g.get("markType", "Marks") for g in _guilds}


# --- Dungeons --------------------------------------------------------------
# Internal ids stay stable across the 2026-05-29 zone swap so existing
# CharVar leaderboards don't reset; display labels track the catalog rename.
_FALLBACK_DUNGEONS = [
    {"id": "whispering_halls",   "label": "The Outer Bastion"},
    {"id": "voidwalker_arena",   "label": "The Voidwalker Arena"},
    {"id": "cloister_of_sorrow", "label": "The Empyreal Paradox"},
    {"id": "eternal_throne",     "label": "The Eternal Throne"},
]
_dungeons = (_CATALOG.get("dungeons") if _CATALOG else None) or _FALLBACK_DUNGEONS
DUNGEON_IDS = tuple(d["id"] for d in _dungeons)
DUNGEON_LABELS = {d["id"]: d["label"] for d in _dungeons}


# --- Timed HNM Kings (spawn-alert feed) -----------------------------------
# The webhook posts when a timed King transitions to UP. The roster (which
# [HNM]<Name> ServerVar maps to which King + zone) comes from catalog.json's
# hnm[], exported from the live HNM module by catalog_json.py — so the alert
# feed can't drift from the HNM doc page. HQ land kings are QM-pop (no timer
# var) and aren't tracked. If catalog.json predates this export the roster is
# empty; the bot still alerts on every [HNM]% var, just with a name derived
# from the var key instead of the pretty zone.
_hnm = (_CATALOG.get("hnm") if _CATALOG else None) or []
HNM_BY_VAR = {
    h["var"]: (h.get("name") or h["var"], h.get("zone") or "")
    for h in _hnm if h.get("var")
}


def _hnm_display(var: str) -> tuple[str, str]:
    """(name, zone) for an [HNM] var. Uses the catalog roster when present,
    else derives a readable name from the var key ('[HNM]King_Arthro' ->
    'King Arthro') so alerts work even with an older catalog.json."""
    if var in HNM_BY_VAR:
        return HNM_BY_VAR[var]
    raw = var[5:] if var.startswith("[HNM]") else var   # strip leading '[HNM]'
    return (raw.replace("_", " ").strip() or var, "")


# --- Broadcast-worthy achievements ----------------------------------------
# Only announce=true milestones reach Discord; quiet ones (FIRST_HUNT,
# TENTH_HUNT, tier firsts, MARKS_1K) stay in-game to avoid channel noise.
_FALLBACK_ACHIEVEMENTS = [
    {"cv": "ACH_CENTURY",     "announce": True, "title": "Centennial Hunter", "desc": "100 Hunting League kills.  No signs of stopping."},
    {"cv": "ACH_THOUSAND",    "announce": True, "title": "Legendary Slayer",  "desc": "1,000 NM kills.  You have earned the title."},
    {"cv": "ACH_APEX_HUNTER", "announce": True, "title": "Apex Hunter",       "desc": "First Tier V kill.  These are the hardest NMs on the server."},
    {"cv": "ACH_MARKS_10K",   "announce": True, "title": "Mark of 10,000",    "desc": "10,000 lifetime Hunt Marks.  A true devotee."},
    {"cv": "ACH_MARKS_100K",  "announce": True, "title": "Mark of 100,000",   "desc": "100,000 lifetime Hunt Marks.  An absolute legend."},
    {"cv": "ACH_INFAMY_500",  "announce": True, "title": "Dungeon Aspirant",  "desc": "500 lifetime Infamy earned from dungeon clears."},
    {"cv": "ACH_INFAMY_1K",   "announce": True, "title": "Dungeon Veteran",   "desc": "1,000 lifetime Infamy.  The dungeons know your name."},
    {"cv": "ACH_INFAMY_5K",   "announce": True, "title": "Dungeon Overlord",  "desc": "5,000 lifetime Infamy.  An unstoppable force of destruction."},
]
_achs = (_CATALOG.get("achievements") if _CATALOG else None) or _FALLBACK_ACHIEVEMENTS
# CharVar name -> (title, description). Only announce=true milestones.
BROADCAST_ACHIEVEMENTS: dict[str, tuple[str, str]] = {
    a["cv"]: (a["title"], a["desc"])
    for a in _achs
    if a.get("announce") and a.get("cv")
}


# --- Ascension (Prestige) milestones --------------------------------------
# Account-wide lifetime ascensions worth a server announcement. Each
# ascension is a full Legend-NM Trial re-clear plus an escalating Hunt
# Marks cost, so we shout milestone crossings, not every ascension.
PRESTIGE_MILESTONES = (1, 10, 25, 50, 100, 250, 500, 1000)


# --- Daily login streak milestones ----------------------------------------
# Broadcast-worthy consecutive-day login streaks, keyed off the in-game
# login_streak.lua system. That module sets a per-threshold reward flag
# (Streak_Reward_<days>) to 1 the first time a player reaches each streak, so we
# watch those flags flip 0 -> 1 (like achievements): each fires exactly once.
STREAK_REWARD_DAYS = {
    "Streak_Reward_7":  7,
    "Streak_Reward_14": 14,
    "Streak_Reward_21": 21,
    "Streak_Reward_30": 30,
}


# ============================================================
# DB snapshot — current per-player state
# ============================================================


def fetch_snapshot(cur):
    """Pull current per-player state from the DB. Returns a dict keyed
    by charname; each value is a flat dict of the CharVars we care about
    plus derived rank indices.

    Only includes non-opted-out players (Leaderboard_OptOut = 0/missing)
    so privacy preferences carry from the in-game system."""
    # Build the full set of CharVars we want in one query. The guild /
    # dungeon / achievement CVs are DERIVED from the catalog-driven tables
    # (GUILDS, DUNGEON_IDS, BROADCAST_ACHIEVEMENTS) so adding one in Lua
    # can't silently desync this query from the event-detection code below.
    interesting_vars = [
        "Title_Trinity_Hunter",
        "Title_Apex_Hunter",
        "WH_AllCleared_Lifetime",
        "Custom_NM_Kills",
        "Leaderboard_OptOut",
        # Total dungeon clears across all dungeons (per-id counters added below).
        "Dungeon_Clears_Total",
        "Infamy_Lifetime",
        # Ascension (Prestige) endgame layer — account-wide lifetime ascensions.
        "Prestige_Ascensions_Total",
        # Daily login streak — per-threshold reward flags (login_streak.lua).
        "Streak_Reward_7", "Streak_Reward_14", "Streak_Reward_21", "Streak_Reward_30",
    ]
    # One rep CharVar per guild.
    interesting_vars += [repCv for _key, _label, repCv in GUILDS]
    # Per-dungeon clear counters — identify WHICH dungeon was just cleared.
    interesting_vars += [f"Dungeon_Clears_{d}" for d in DUNGEON_IDS]
    # Broadcast-worthy personal achievements (announce=true in achievements.lua).
    interesting_vars += list(BROADCAST_ACHIEVEMENTS.keys())
    placeholders = ",".join(["%s"] * len(interesting_vars))
    cur.execute(
        f"""
        SELECT c.charname, cv.varname, cv.value
          FROM chars c
          LEFT JOIN char_vars cv ON cv.charid = c.charid
                                AND cv.varname IN ({placeholders})
                                AND (cv.expiry = 0 OR cv.expiry > UNIX_TIMESTAMP())
        """,
        interesting_vars,
    )
    raw: dict[str, dict[str, int]] = {}
    for charname, varname, value in cur.fetchall():
        bucket = raw.setdefault(charname, {})
        if varname:
            bucket[varname] = int(value or 0)

    # Drop opt-outs entirely.
    raw = {n: v for n, v in raw.items() if v.get("Leaderboard_OptOut", 0) == 0}

    # Derive rank indices per guild for diff convenience.
    for name, vars_ in raw.items():
        for key, _label, repCv in GUILDS:
            rep = vars_.get(repCv, 0)
            vars_[f"_rank_{key}"] = rank_index_for_rep(rep)
    return raw


# ============================================================
# Timed HNM spawn tracking
# ============================================================
# HNM spawn state lives in server_variables as [HNM]<Name> = the Unix time
# the King will (re)pop (same var the in-game module and the status page read).
#   pop == 0 / absent  -> that zone hasn't initialized a timer yet
#   now <  pop         -> waiting; pops at pop
#   now >= pop > 0      -> UP
# We post once per *distinct* pop time: keying the announced map on the exact
# pop value means a kill (which reschedules pop to a future time) is silent,
# and the next time that new pop time arrives the King fires exactly once.


def fetch_hnm_poptimes(cur) -> dict[str, int]:
    """Current [HNM]<Name> pop-time ServerVars as {var: unix_pop_time}."""
    cur.execute("SELECT name, value FROM server_variables WHERE name LIKE '[HNM]%'")
    out: dict[str, int] = {}
    for name, value in cur.fetchall():
        try:
            out[name] = int(value or 0)
        except (TypeError, ValueError):
            out[name] = 0
    return out


def _hnm_baseline(poptimes: dict[str, int], now: int) -> dict[str, int]:
    """Currently-UP kings as {var: pop} — the 'already announced' seed used on
    first run / first feature-run so pre-existing spawns don't flood."""
    return {var: pop for var, pop in poptimes.items() if pop > 0 and now >= pop}


def detect_hnm_spawns(poptimes: dict[str, int], announced: dict[str, int], now: int):
    """Yield ('hnm_spawn', var, name, zone) for each King that is UP now and
    whose current pop time hasn't been announced yet."""
    for var, pop in poptimes.items():
        if pop > 0 and now >= pop and announced.get(var) != pop:
            name, zone = _hnm_display(var)
            yield ("hnm_spawn", var, name, zone)


# ============================================================
# Patch-notes cross-post (local git log -> Discord)
# ============================================================
# Mirrors the filtering in tools/docgen/generators/changelog.py. The bot can't
# import that module (it lives on the docs branch, absent from the live server
# checkout), so this small prefix list is duplicated by necessity — keep the
# two in sync if either changes. Posts commits in REPO_ROOT since the last
# announced SHA (stored in state.json), oldest-first, merges + chore commits
# filtered out.
_PATCH_SKIP_PREFIXES = ("Merge", "Auto-", "docs: auto")
# Unit separator — safe field delimiter for `git log --format` (won't appear
# in a commit subject the way '|' can).
_GIT_FS = "\x1f"


def _git(args: list[str], cwd: Path) -> str | None:
    """Run a git command in cwd; return stdout, or None if git is unavailable
    or the command failed."""
    try:
        r = subprocess.run(
            ["git", *args], cwd=str(cwd),
            capture_output=True, text=True, timeout=20,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired, OSError):
        return None
    if r.returncode != 0:
        return None
    return r.stdout


def git_head(cwd: Path) -> str | None:
    out = _git(["rev-parse", "HEAD"], cwd)
    return out.strip() if out else None


def _sha_exists(cwd: Path, sha: str) -> bool:
    """True if sha names a commit in this repo (guards against a stored SHA
    that vanished after a history rewrite / fresh clone)."""
    return _git(["cat-file", "-e", f"{sha}^{{commit}}"], cwd) is not None


def fetch_new_commits(cwd: Path, since_sha: str, cap: int) -> list[tuple[str, str]] | None:
    """[(sha, subject)] for commits in since_sha..HEAD, oldest-first, with
    merge/chore subjects filtered out. None if git is unavailable."""
    out = _git(
        ["log", "--no-merges", "--reverse", f"--format=%H{_GIT_FS}%s", f"{since_sha}..HEAD"],
        cwd,
    )
    if out is None:
        return None
    commits: list[tuple[str, str]] = []
    for line in out.splitlines():
        if _GIT_FS not in line:
            continue
        sha, subject = line.split(_GIT_FS, 1)
        subject = subject.strip()
        if not subject or any(subject.startswith(p) for p in _PATCH_SKIP_PREFIXES):
            continue
        commits.append((sha.strip(), subject))
    return commits[:max(0, cap)] if cap else commits


def format_patch_notes(commits: list[tuple[str, str]], total: int, cfg) -> str:
    """Render a single patch-notes post. `total` is the unfiltered-by-cap count
    so we can say '…and N more' when capped."""
    role = str(cfg.get("PING_ROLE_ON_PATCH", "") or "")
    prefix = f"<@&{role}>  " if role else ""
    header = (
        f"{prefix}:scroll: **Server update** — "
        f"{total} new change{'s' if total != 1 else ''}:"
    )
    lines = [header]
    for _sha, subject in commits:
        lines.append(f"• {subject.replace('`', chr(39))}")
    if total > len(commits):
        lines.append(f"…and {total - len(commits)} more.")
    msg = "\n".join(lines)
    # Discord hard-caps a message at 2000 chars; stay well under.
    if len(msg) > 1900:
        msg = msg[:1897] + "…"
    return msg


# ============================================================
# Discord posting
# ============================================================

def post_to_discord(cfg, content: str) -> bool:
    """POST a message to the configured webhook. Returns True on success,
    False on any error (logs the failure)."""
    payload = {
        "content":  content,
        "username": cfg["BOT_USERNAME"],
        # Without this, role pings and @here render as plain text — Discord
        # webhooks silently strip mentions unless allowed_mentions opts in.
        # We allow roles + everyone (@here) so the configured ping config
        # actually pings; users still require @<userid> which we don't use.
        "allowed_mentions": {"parse": ["roles", "everyone"]},
    }
    if cfg.get("BOT_AVATAR_URL"):
        payload["avatar_url"] = cfg["BOT_AVATAR_URL"]

    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        cfg["WEBHOOK_URL"],
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            # Discord returns 204 No Content on success.
            if 200 <= resp.status < 300:
                return True
            print(f"[discord_bot] unexpected status {resp.status}: {resp.read()!r}")
            return False
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        print(f"[discord_bot] HTTP {e.code}: {body}")
        # 429 = rate limit; bail out (we'll retry on next run)
        return False
    except urllib.error.URLError as e:
        print(f"[discord_bot] webhook unreachable: {e.reason}")
        return False


# ============================================================
# Event detection (diff current vs last-seen)
# ============================================================

def detect_events(snapshot, last_seen, cfg):
    """Walk every player and yield event tuples for everything new.

    Yields:
        ('rank_up',         player, guild_key, new_rank_idx, new_rank_label, amp_pct)
        ('trinity',         player)
        ('apex',            player)
        ('sweep',           player, total_sweeps)
        ('dungeon_clear',   player, dungeon_id, delta_count)
        ('kills',           player, delta)  -- only if ANNOUNCE_EVERY_KILL
        ('achievement',     player, ach_var, title, desc)
        ('prestige',        player, lifetime_ascensions, milestone)
        ('streak',          player, best_streak, milestone)
    """
    for name, vars_ in snapshot.items():
        prev = last_seen.get(name, {})

        # Per-guild rank-ups
        for key, label, _repCv in GUILDS:
            new_idx = vars_.get(f"_rank_{key}", 1)
            old_idx = prev.get(f"_rank_{key}", new_idx)   # default = same (no event on first sighting)
            if new_idx > old_idx and new_idx >= cfg["MIN_RANK_TO_ANNOUNCE"]:
                yield ("rank_up", name, key, new_idx, RANK_LABELS[new_idx - 1], RANK_AMP_PCT[new_idx - 1])

        # Trinity / Apex capstones (one-time flips 0 -> 1)
        if vars_.get("Title_Trinity_Hunter", 0) == 1 and prev.get("Title_Trinity_Hunter", 0) == 0:
            yield ("trinity", name)
        if vars_.get("Title_Apex_Hunter", 0) == 1 and prev.get("Title_Apex_Hunter", 0) == 0:
            yield ("apex", name)

        # Weekly sweeps — counter can climb +1 each week the player
        # clears all 5 objectives. Announce each delta.
        new_sweeps = vars_.get("WH_AllCleared_Lifetime", 0)
        old_sweeps = prev.get("WH_AllCleared_Lifetime", new_sweeps)
        if new_sweeps > old_sweeps:
            yield ("sweep", name, new_sweeps)

        # Dungeon clears — emit one event per *dungeon* that ticked up
        # since the last snapshot. The per-id counters tell us which
        # specific dungeon was cleared. If a player cleared two
        # different dungeons in the same poll window, both fire (and
        # they'll race for line ordering — accept that).
        for dungeon_id in DUNGEON_IDS:
            cv = f"Dungeon_Clears_{dungeon_id}"
            new_v = vars_.get(cv, 0)
            old_v = prev.get(cv, new_v)
            if new_v > old_v:
                yield ("dungeon_clear", name, dungeon_id, new_v - old_v)

        # Per-kill (off by default — usually too chatty)
        if cfg.get("ANNOUNCE_EVERY_KILL"):
            new_kills = vars_.get("Custom_NM_Kills", 0)
            old_kills = prev.get("Custom_NM_Kills", new_kills)
            if new_kills > old_kills:
                yield ("kills", name, new_kills - old_kills)

        # Broadcast-worthy personal achievements (flip 0 → non-zero).
        # The ACH_* CharVar stores the Unix timestamp of when it was earned, so
        # any non-zero value means "earned"; zero/missing means "not yet".
        for ach_var in BROADCAST_ACHIEVEMENTS:
            new_v = vars_.get(ach_var, 0)
            old_v = prev.get(ach_var, new_v)   # default = same (no event on first sighting)
            if new_v != 0 and old_v == 0:
                title, desc = BROADCAST_ACHIEVEMENTS[ach_var]
                yield ("achievement", name, ach_var, title, desc)

        # Ascension (Prestige) — announce milestone crossings of the
        # account-wide lifetime ascension count. Fires once per crossing
        # (for the highest milestone passed since the last snapshot).
        new_asc = vars_.get("Prestige_Ascensions_Total", 0)
        old_asc = prev.get("Prestige_Ascensions_Total", new_asc)
        if new_asc > old_asc:
            crossed = [m for m in PRESTIGE_MILESTONES if old_asc < m <= new_asc]
            if crossed:
                yield ("prestige", name, new_asc, max(crossed))

        # Daily login streak — broadcast when a player first reaches a streak
        # milestone, via login_streak.lua's per-threshold reward flags
        # (Streak_Reward_<days> flips 0 -> 1, like an achievement). Fires once
        # per threshold per player; gated by an optional config flag.
        if cfg.get("STREAK_ALERTS_ENABLED", True):
            for streak_var, days in STREAK_REWARD_DAYS.items():
                new_v = vars_.get(streak_var, 0)
                old_v = prev.get(streak_var, new_v)
                if new_v != 0 and old_v == 0:
                    yield ("streak", name, days, days)


# ============================================================
# Message formatters
# ============================================================

# GUILD_LABELS, GUILD_MARK_TYPES, DUNGEON_IDS, DUNGEON_LABELS and
# BROADCAST_ACHIEVEMENTS are defined up in the Catalog section, derived from
# catalog.json so they can't drift from the Lua source.


def _build_ping_prefix(cfg, *, role_key: str, here_key: str) -> str:
    """Compose the mention prefix for an event. Honors PING_ROLE_ON_* and
    PING_HERE_ON_* config flags. Empty string when both are disabled —
    the event still posts cleanly, just without a ping."""
    parts = []
    role_id = cfg.get(role_key, "")
    if role_id:
        parts.append(f"<@&{role_id}>")
    if cfg.get(here_key, False):
        parts.append("@here")
    if not parts:
        return ""
    return " ".join(parts) + "  "   # trailing spaces -> nice visual gap


def format_event(ev, cfg) -> str:
    kind = ev[0]
    if kind == "rank_up":
        _, name, guild, idx, label, amp = ev
        # Grandmaster-only ping (configurable). Lower ranks post without
        # mentions to keep the channel readable.
        prefix = ""
        if idx >= 5 and cfg.get("PING_ROLE_ON_GRANDMASTER"):
            prefix = f"<@&{cfg['PING_ROLE_ON_GRANDMASTER']}>  "
        return (
            f"{prefix}:shield: **{name}** has risen to **{label}** of the "
            f"{GUILD_LABELS[guild]}!  (+{amp}% {GUILD_MARK_TYPES[guild]})"
        )
    if kind == "trinity":
        _, name = ev
        prefix = _build_ping_prefix(cfg,
            role_key="PING_ROLE_ON_TRINITY",
            here_key="PING_HERE_ON_TRINITY")
        return (
            f"{prefix}:trophy: **TRINITY HUNTER**: **{name}** is now a master "
            "of all three Reforge guilds! (+25% to AF/Relic/Empy Marks)"
        )
    if kind == "apex":
        _, name = ev
        prefix = _build_ping_prefix(cfg,
            role_key="PING_ROLE_ON_APEX",
            here_key="PING_HERE_ON_APEX")
        return (
            f"{prefix}:crown: **APEX HUNTER ACHIEVED**: **{name}** has "
            "mastered all four guilds! (+50% to ALL marks — server bragging rights)"
        )
    if kind == "sweep":
        _, name, total = ev
        return (
            f":star: **{name}** swept the Weekly Hunt Board! "
            f"(All 5 weekly objectives cleared.  Lifetime sweeps: **{total}**)"
        )
    if kind == "dungeon_clear":
        _, name, dungeon_id, delta = ev
        label = DUNGEON_LABELS.get(dungeon_id, dungeon_id)
        # delta > 1 only when multiple clears happened within one
        # poll interval (5 min default) — rare but possible.
        if delta > 1:
            return (
                f":key: **{name}** cleared **{label}** "
                f"({delta} times since last poll)!"
            )
        return f":key: **{name}** cleared **{label}**!"
    if kind == "kills":
        _, name, delta = ev
        return f":crossed_swords: **{name}** scored **{delta}** NM kills."
    if kind == "achievement":
        _, name, _ach_var, title, desc = ev
        return (
            f":medal: **{name}** earned the **{title}** achievement!  {desc}"
        )
    if kind == "prestige":
        _, name, _total, milestone = ev
        if milestone == 1:
            return (
                f":sparkles: **{name}** performed their **first Ascension** — "
                "rising above Legend into the Prestige ranks!"
            )
        if milestone >= 100:
            return (
                f":sparkles: **PARAGON**: **{name}** has reached **{milestone} "
                "lifetime Ascensions** — a paragon ascending far beyond Legend!"
            )
        return (
            f":sparkles: **{name}** reached **{milestone} lifetime Ascensions** — "
            "ascending ever beyond Legend!"
        )
    if kind == "streak":
        _, name, _best, milestone = ev
        if milestone >= 365:
            return (
                f":fire: **{name}** has logged in **{milestone} days running** — "
                "a full year of devotion. Unbreakable!"
            )
        return (
            f":fire: **{name}** is on a **{milestone}-day login streak** — "
            "the kind of dedication that keeps the realm alive!"
        )
    if kind == "hnm_spawn":
        _, _var, name, zone = ev
        prefix = _build_ping_prefix(cfg,
            role_key="PING_ROLE_ON_HNM",
            here_key="PING_HERE_ON_HNM")
        where = f" in **{zone}**" if zone else ""
        return (
            f"{prefix}:dragon: **{name}** has spawned{where}! "
            "A timed King is up for the taking — rally your party!"
        )
    return f"[unknown event: {ev}]"


# ============================================================
# Digest composition
# ============================================================

def fetch_digest_data(cur, lookback_days: int):
    """Pull aggregated stats for a digest window.

    NB: We don't have per-event timestamps, so 'kills since X days ago'
    is approximated by comparing Custom_NM_Kills to the snapshot we
    saved on the last-digest run. That snapshot lives in state.json
    under last_digest_snapshot.
    """
    # The actual delta is computed against the saved snapshot at call
    # time. This function just pulls the CURRENT totals.
    cur.execute(
        """
        SELECT c.charname, cv.value
          FROM chars c
          JOIN char_vars cv ON cv.charid = c.charid
                           AND cv.varname = 'Custom_NM_Kills'
                           AND (cv.expiry = 0 OR cv.expiry > UNIX_TIMESTAMP())
         LEFT JOIN char_vars opt ON opt.charid = c.charid
                                AND opt.varname = 'Leaderboard_OptOut'
         WHERE (opt.value IS NULL OR opt.value = 0)
        """,
    )
    return {n: int(v or 0) for n, v in cur.fetchall()}


def compose_daily_digest(now_utc, current_kills, prev_kills):
    """One-line + top-3 leaderboard for kills since last daily digest."""
    deltas = []
    for name, current in current_kills.items():
        delta = current - prev_kills.get(name, current)
        if delta > 0:
            deltas.append((name, delta))
    deltas.sort(key=lambda x: -x[1])
    total = sum(d for _, d in deltas)

    date_str = now_utc.strftime("%Y-%m-%d UTC")
    if not deltas:
        return f"**Daily Recap — {date_str}**\nNo NM activity in the last 24h."
    lines = [
        f"**Daily Recap — {date_str}**",
        f"Last 24h: **{total}** custom NMs slain by **{len(deltas)}** hunter(s).",
    ]
    if deltas[:3]:
        lines.append("Top hunters:")
        for i, (name, delta) in enumerate(deltas[:3], 1):
            medal = {1: ":first_place:", 2: ":second_place:", 3: ":third_place:"}.get(i, "")
            lines.append(f"  {medal} {name} — {delta} kills")
    return "\n".join(lines)


def compose_weekly_digest(now_utc, current_kills, prev_kills, snapshot):
    """Wider weekly recap — top 5 + guild standings."""
    deltas = []
    for name, current in current_kills.items():
        delta = current - prev_kills.get(name, current)
        if delta > 0:
            deltas.append((name, delta))
    deltas.sort(key=lambda x: -x[1])
    total = sum(d for _, d in deltas)

    date_str = now_utc.strftime("%Y-%m-%d UTC")
    lines = [
        f"**Weekly Recap — Week ending {date_str}**",
        f"Last 7 days: **{total}** custom NMs slain by **{len(deltas)}** hunter(s).",
    ]
    if deltas[:5]:
        lines.append("**Top kills this week:**")
        for i, (name, delta) in enumerate(deltas[:5], 1):
            lines.append(f"  {i}. {name} — {delta} kills")

    # Guild leaderboard: top 5 by Grandmaster-count (highest tier
    # achieved across the 4 guilds, then total rep as tiebreaker).
    rows = []
    for name, vars_ in snapshot.items():
        ranks = [vars_.get(f"_rank_{k}", 1) for k, _, _ in GUILDS]
        rep_total = sum(vars_.get(c, 0) for _, _, c in GUILDS)
        rows.append((name, ranks, rep_total))
    rows.sort(key=lambda r: (-max(r[1]), -r[2]))
    if rows[:3]:
        lines.append("**Hunter's Guild standings:**")
        for name, ranks, _rep in rows[:3]:
            rank_strs = []
            for (key, _, _), ridx in zip(GUILDS, ranks):
                if ridx > 1:
                    rank_strs.append(f"{key.upper()}: {RANK_LABELS[ridx - 1]}")
            tag = ", ".join(rank_strs) if rank_strs else "Apprentice (all)"
            lines.append(f"  • {name} — {tag}")

    lines.append("")
    lines.append(":dart: Weekly Hunt Board has reset — talk to the Hunt Board NPC for new objectives!")
    return "\n".join(lines)


# ============================================================
# Digest cadence check
# ============================================================

def daily_due(now_utc, last_iso, cfg):
    if not cfg.get("DAILY_DIGEST_ENABLED", True):
        return False
    if now_utc.hour < cfg["DAILY_DIGEST_HOUR_UTC"]:
        return False
    if not last_iso:
        return True
    last = datetime.fromisoformat(last_iso.replace("Z", "+00:00"))
    return (now_utc.date() != last.date())


def weekly_due(now_utc, last_iso, cfg):
    if not cfg.get("WEEKLY_DIGEST_ENABLED", True):
        return False
    if now_utc.weekday() != cfg["WEEKLY_DIGEST_DAY"]:
        return False
    if now_utc.hour < cfg["WEEKLY_DIGEST_HOUR_UTC"]:
        return False
    if not last_iso:
        return True
    last = datetime.fromisoformat(last_iso.replace("Z", "+00:00"))
    # Strictly past the last weekly digest date — same calendar day re-runs are skipped.
    return (now_utc.date() != last.date())


# ============================================================
# Main
# ============================================================

def main() -> int:
    cfg = load_config()

    conn = connect(REPO_ROOT)
    if conn is None:
        print("[discord_bot] DB unreachable. Set LEGENDARY_LIVE_ROOT in env or fix tools/docgen/_db.py.")
        return 2
    cur = conn.cursor()

    try:
        snapshot = fetch_snapshot(cur)
        hnm_poptimes = fetch_hnm_poptimes(cur)
    finally:
        try:
            cur.close()
            conn.close()
        except Exception:
            pass

    state = load_state()
    last_seen = state.get("last_seen", {})
    now_utc = datetime.now(timezone.utc)
    now_unix = int(time.time())

    # First run: bootstrap state silently. No historical event flood.
    if not state.get("bootstrapped"):
        state["last_seen"]      = snapshot
        state["bootstrapped"]   = True
        state["last_digest_snapshot_kills"] = {
            n: v.get("Custom_NM_Kills", 0) for n, v in snapshot.items()
        }
        # Seed the HNM + patch-notes baselines too, so the *next* run is already
        # live and never replays kings that were up / commits that landed before
        # the bot existed.
        state["hnm_announced"]  = _hnm_baseline(hnm_poptimes, now_unix)
        state["last_patch_sha"] = git_head(REPO_ROOT)
        save_state(state)
        print(f"[discord_bot] bootstrapped state for {len(snapshot)} player(s); no events posted on first run")
        return 0

    # Detect and post per-event posts.
    posted = 0
    failed = 0
    for ev in detect_events(snapshot, last_seen, cfg):
        msg = format_event(ev, cfg)
        if post_to_discord(cfg, msg):
            posted += 1
        else:
            failed += 1
        # Small spacing so Discord shows them in order without rate-limit warning.
        time.sleep(0.4)

    # --- Timed HNM spawn alerts ---------------------------------------------
    if cfg.get("HNM_ALERTS_ENABLED", True):
        if "hnm_announced" not in state:
            # First time this feature runs on an already-bootstrapped deployment:
            # seed currently-up kings so we don't flood, then start alerting next run.
            state["hnm_announced"] = _hnm_baseline(hnm_poptimes, now_unix)
            print(f"[discord_bot] seeded HNM baseline ({len(state['hnm_announced'])} king(s) up); alerts begin next run")
        else:
            announced = state["hnm_announced"]
            for ev in detect_hnm_spawns(hnm_poptimes, announced, now_unix):
                if post_to_discord(cfg, format_event(ev, cfg)):
                    posted += 1
                    announced[ev[1]] = hnm_poptimes[ev[1]]   # record this pop as announced
                else:
                    failed += 1
                time.sleep(0.4)
            # Drop announced entries for vars that no longer exist (keeps state tidy).
            for var in [v for v in announced if v not in hnm_poptimes]:
                del announced[var]

    # --- Patch-notes cross-post ---------------------------------------------
    if cfg.get("PATCH_NOTES_ENABLED", True):
        head = git_head(REPO_ROOT)
        if head is None:
            print("[discord_bot] patch-notes: git unavailable, skipping")
        else:
            last = state.get("last_patch_sha")
            if last and not _sha_exists(REPO_ROOT, last):
                print("[discord_bot] patch-notes: stored SHA missing (history rewrite?); rebaselining")
                last = None
            if not last:
                state["last_patch_sha"] = head
                print("[discord_bot] patch-notes: baseline set to HEAD; new commits post from next run")
            else:
                cap = int(cfg.get("PATCH_NOTES_MAX", 15) or 15)
                commits = fetch_new_commits(REPO_ROOT, last, cap)
                if commits is None:
                    print("[discord_bot] patch-notes: git log failed, skipping")
                elif not commits:
                    # No notable commits — advance the baseline anyway so filtered
                    # (merge/chore) commits aren't re-examined every run.
                    state["last_patch_sha"] = head
                else:
                    # commits is already capped; recover the true count for "…and N more".
                    raw = fetch_new_commits(REPO_ROOT, last, 0)
                    total = len(raw) if raw is not None else len(commits)
                    if post_to_discord(cfg, format_patch_notes(commits, total, cfg)):
                        posted += 1
                        state["last_patch_sha"] = head
                    else:
                        failed += 1
                    time.sleep(0.4)

    # Check digest cadence.
    last_daily  = state.get("last_digest", {}).get("daily")
    last_weekly = state.get("last_digest", {}).get("weekly")
    digest_snap_kills = state.get("last_digest_snapshot_kills", {})
    current_kills = {n: v.get("Custom_NM_Kills", 0) for n, v in snapshot.items()}

    if daily_due(now_utc, last_daily, cfg):
        msg = compose_daily_digest(now_utc, current_kills, digest_snap_kills)
        if post_to_discord(cfg, msg):
            posted += 1
            state.setdefault("last_digest", {})["daily"] = now_utc.isoformat()
            # Daily resets the kill-snapshot baseline. Weekly uses the
            # SAME baseline (we'd want two separate baselines if both
            # need exact 24h/7d windows, but daily after daily after
            # daily is fine for a small server).
            state["last_digest_snapshot_kills"] = current_kills
        else:
            failed += 1
        time.sleep(0.4)

    if weekly_due(now_utc, last_weekly, cfg):
        msg = compose_weekly_digest(now_utc, current_kills, digest_snap_kills, snapshot)
        if post_to_discord(cfg, msg):
            posted += 1
            state.setdefault("last_digest", {})["weekly"] = now_utc.isoformat()
            # Weekly digest ALSO resets the kill baseline if it fired
            # on the same run as daily (idempotent — second reset is
            # a no-op).
            state["last_digest_snapshot_kills"] = current_kills
        else:
            failed += 1

    # Save the new last_seen snapshot LAST, so a mid-run crash doesn't
    # advance the cursor (we'd rather replay events than skip them).
    state["last_seen"] = snapshot
    save_state(state)

    print(f"[discord_bot] posted {posted} message(s), {failed} failure(s)")
    return 3 if failed > 0 else 0


if __name__ == "__main__":
    rc = main()
    # Dead-man's-switch: record this run so the docs status page can flag the
    # webhook bot as STALE if the scheduled task silently stops firing. ok only
    # when the pass was clean (rc 0); rc 2 = DB unreachable, 3 = post failures.
    write_heartbeat(REPO_ROOT, "discord_webhook", ok=(rc == 0), detail=f"exit {rc}")
    sys.exit(rc)
