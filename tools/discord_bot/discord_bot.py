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
import sys
import time
import urllib.request
import urllib.error
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

# Reuse the docgen DB connection helper. Keeps one place for credentials.
THIS_DIR  = Path(__file__).resolve().parent
REPO_ROOT = THIS_DIR.parents[1]
sys.path.insert(0, str(REPO_ROOT))

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
# DB snapshot — current per-player state
# ============================================================

# Hunter's Guild rank thresholds, must match hunters_guild_catalog.lua.
# Duplicated here so the bot can run without Lua deps. If you change
# the Lua thresholds, mirror them here.
RANK_THRESHOLDS = [
    (0,      "Apprentice"),
    (500,    "Journeyman"),
    (5000,   "Veteran"),
    (25000,  "Master"),
    (100000, "Grandmaster"),
]
RANK_LABELS  = [t[1] for t in RANK_THRESHOLDS]
RANK_AMP_PCT = [0, 10, 25, 50, 100]


def rank_index_for_rep(rep: int) -> int:
    """Map a rep value to a rank index (1..5). Walks top-down so the
    highest threshold met wins."""
    for i in range(len(RANK_THRESHOLDS) - 1, -1, -1):
        if rep >= RANK_THRESHOLDS[i][0]:
            return i + 1
    return 1


GUILDS = [
    ("af",    "AF Hunters' Guild",      "Guild_AF_Rep"),
    ("relic", "Relic Hunters' Guild",   "Guild_Relic_Rep"),
    ("empy",  "Empy Hunters' Guild",    "Guild_Empy_Rep"),
    ("hl",    "League Hunters' Guild",  "Guild_HL_Rep"),
]


def fetch_snapshot(cur):
    """Pull current per-player state from the DB. Returns a dict keyed
    by charname; each value is a flat dict of the CharVars we care about
    plus derived rank indices.

    Only includes non-opted-out players (Leaderboard_OptOut = 0/missing)
    so privacy preferences carry from the in-game system."""
    # Build the full set of CharVars we want in one query.
    interesting_vars = [
        "Guild_AF_Rep",
        "Guild_Relic_Rep",
        "Guild_Empy_Rep",
        "Guild_HL_Rep",
        "Title_Trinity_Hunter",
        "Title_Apex_Hunter",
        "WH_AllCleared_Lifetime",
        "Custom_NM_Kills",
        "Leaderboard_OptOut",
        # Dungeon system — total clears across all 3 dungeons, plus
        # per-dungeon clear counters so we can identify WHICH dungeon
        # someone just cleared (delta per-id since last snapshot).
        "Dungeon_Clears_Total",
        "Dungeon_Clears_whispering_halls",
        "Dungeon_Clears_voidwalker_arena",
        "Dungeon_Clears_cloister_of_sorrow",
        "Infamy_Lifetime",
        # Broadcast-worthy personal achievements (announce=true in achievements.lua).
        # Quiet milestones (FIRST_HUNT, TENTH_HUNT, tier firsts, MARKS_1K) stay
        # in-game only — no Discord noise for routine early-game steps.
        "ACH_CENTURY",
        "ACH_THOUSAND",
        "ACH_APEX_HUNTER",
        "ACH_MARKS_10K",
        "ACH_MARKS_100K",
    ]
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


# ============================================================
# Message formatters
# ============================================================

# Broadcast-worthy achievements tracked by the bot.  Keys are CharVar names;
# values are (title, short_description) pairs matching achievements.lua.
# Only announce=True milestones are listed here — quiet ones stay in-game.
BROADCAST_ACHIEVEMENTS: dict[str, tuple[str, str]] = {
    "ACH_CENTURY":     ("Centennial Hunter",  "100 Hunting League kills.  No signs of stopping."),
    "ACH_THOUSAND":    ("Legendary Slayer",   "1,000 NM kills.  An absolute legend."),
    "ACH_APEX_HUNTER": ("Apex Hunter",        "First Tier V kill — the hardest NMs on the server!"),
    "ACH_MARKS_10K":   ("Mark of 10,000",     "10,000 lifetime Hunt Marks.  A true devotee."),
    "ACH_MARKS_100K":  ("Mark of 100,000",    "100,000 lifetime Hunt Marks.  A mythic accomplishment."),
}

GUILD_LABELS = {k: lbl for k, lbl, _ in GUILDS}
GUILD_MARK_TYPES = {
    "af":    "AF Marks",
    "relic": "Relic Marks",
    "empy":  "Empy Marks",
    "hl":    "Hunt Marks",
}

# Dungeon ID → display label. Mirrors dungeon_catalog.lua. If you add
# new dungeons to the Lua catalog, add their ids here and to the
# `interesting_vars` list in fetch_snapshot() above.
DUNGEON_IDS = (
    "whispering_halls",
    "voidwalker_arena",
    "cloister_of_sorrow",
)
DUNGEON_LABELS = {
    # Internal ids stay stable (whispering_halls, cloister_of_sorrow)
    # across the 2026-05-29 zone swap so existing CharVar leaderboards
    # don't reset. Display labels track the catalog rename.
    "whispering_halls":   "The Outer Bastion",
    "voidwalker_arena":   "The Voidwalker Arena",
    "cloister_of_sorrow": "The Empyreal Paradox",
}


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
    finally:
        try:
            cur.close()
            conn.close()
        except Exception:
            pass

    state = load_state()
    last_seen = state.get("last_seen", {})
    now_utc = datetime.now(timezone.utc)

    # First run: bootstrap state silently. No historical event flood.
    if not state.get("bootstrapped"):
        state["last_seen"]      = snapshot
        state["bootstrapped"]   = True
        state["last_digest_snapshot_kills"] = {
            n: v.get("Custom_NM_Kills", 0) for n, v in snapshot.items()
        }
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
    sys.exit(main())
