"""Generate one markdown profile page per character + an index.

Reads from the live DB and writes:

    docs/community/players/index.md            <- roster + quick-stats table
    docs/community/players/<slugged-name>.md   <- one page per character

Each profile shows: identity (race/nation/age), time played, current main/sub
+ all 22 job levels, Hunting League rank/marks, Augment Sage rank/affinities,
Reforge marks (current + lifetime per track), Trust count, deaths, and any
locked-in speed-record timestamps.

Respects `Leaderboard_OptOut` — opted-out characters get no profile and
don't appear on the index.

Profile pages are excluded from the MkDocs nav tree via
`validation.nav.omitted_files: info` in mkdocs.yml so we don't have to
list every character explicitly. The index links to each one.

Skips silently if there's no DB connection (CI without LEGENDARY_LIVE_ROOT).
"""
from __future__ import annotations

import json
import re
from datetime import datetime
from pathlib import Path

from tools.docgen._db import connect


_PROFILES_SUBDIR = "community/players"

NATIONS = {0: "San d'Oria", 1: "Bastok", 2: "Windurst"}

# xi.job enum mapping. Kept here so the generator has no Lua deps.
JOB_ABBR = {
    1:  "WAR", 2:  "MNK", 3:  "WHM", 4:  "BLM", 5:  "RDM", 6:  "THF",
    7:  "PLD", 8:  "DRK", 9:  "BST", 10: "BRD", 11: "RNG", 12: "SAM",
    13: "NIN", 14: "DRG", 15: "SMN", 16: "BLU", 17: "COR", 18: "PUP",
    19: "DNC", 20: "SCH", 21: "GEO", 22: "RUN",
}
JOB_COLS = ("war", "mnk", "whm", "blm", "rdm", "thf", "pld", "drk",
            "bst", "brd", "rng", "sam", "nin", "drg", "smn", "blu",
            "cor", "pup", "dnc", "sch", "geo", "run")

# Mirror of leaderboards.py _format_duration so profiles can render speed
# records the same way.
def _format_duration(seconds: int) -> str:
    if seconds < 60:
        return f"{seconds}s"
    if seconds < 3600:
        m, s = divmod(seconds, 60)
        return f"{m}m {s}s" if s else f"{m}m"
    if seconds < 86400:
        h, rem = divmod(seconds, 3600)
        m = rem // 60
        return f"{h}h {m}m" if m else f"{h}h"
    d, rem = divmod(seconds, 86400)
    h = rem // 3600
    return f"{d}d {h}h" if h else f"{d}d"


def _slug(name: str) -> str:
    """Charname -> safe filename. FFXI names are alphanumeric but be defensive."""
    s = re.sub(r"[^A-Za-z0-9]+", "_", name).strip("_").lower()
    return s or "anon"


def _bit_count(n: int) -> int:
    return bin(int(n) & 0xFFFFFFFFFFFFFFFF).count("1") if n else 0


# ---- Catalog-driven metadata (guild ranks, capstones, achievements) --------
#
# Sourced from tools/docgen/catalog.json — the single source of truth exported
# from the live Lua by catalog_json.py (which runs first in the docgen pass, so
# the JSON is always fresh). The fallbacks mirror the catalog so a missing or
# malformed file still renders sane pages instead of blanking the section.

_GRANDMASTER_REP = 100000

_GUILD_RANKS_FALLBACK = [
    (1, "Apprentice", 0),
    (2, "Journeyman", 500),
    (3, "Veteran", 5000),
    (4, "Master", 25000),
    (5, "Grandmaster", 100000),
]

_GUILDS_FALLBACK = [
    ("af",    "AF Hunters' Guild",       "Guild_AF_Rep"),
    ("relic", "Relic Hunters' Guild",    "Guild_Relic_Rep"),
    ("empy",  "Empyrean Hunters' Guild", "Guild_Empy_Rep"),
    ("hl",    "League Hunters' Guild",   "Guild_HL_Rep"),
]

_CAPSTONES_FALLBACK = [
    {"key": "trinity", "cv": "Title_Trinity_Hunter", "label": "Trinity Hunter",
     "requires": ["af", "relic", "empy"], "bonus": 0.25},
    {"key": "apex", "cv": "Title_Apex_Hunter", "label": "Apex Hunter",
     "requires": ["af", "relic", "empy", "hl"], "bonus": 0.5},
]


def _load_meta(repo_root: Path) -> dict:
    """Read guild / rank / capstone / achievement metadata from catalog.json.

    Returns a dict:
        guilds     -> [(key, label, repCv), ...]            (display order)
        ranks      -> [(idx, label, minRep), ...]           (sorted by minRep)
        capstones  -> [{key, cv, label, requires, bonus}, ...]
        ach_titles -> {achievementCv: title}                (catalog order)
    Degrades to the fallback constants if catalog.json is unreadable."""
    meta = {
        "guilds":     [t for t in _GUILDS_FALLBACK],
        "ranks":      sorted(_GUILD_RANKS_FALLBACK, key=lambda t: t[2]),
        "capstones":  [dict(c) for c in _CAPSTONES_FALLBACK],
        "ach_titles": {},
    }
    catalog = Path(__file__).resolve().parent.parent / "catalog.json"
    try:
        data = json.loads(catalog.read_text(encoding="utf-8"))
    except Exception as e:  # noqa: BLE001
        print(f"[player_profiles] catalog.json unavailable ({e}); using fallback metadata")
        return meta

    if data.get("guilds"):
        meta["guilds"] = [(g["key"], g["label"], g["repCv"]) for g in data["guilds"]]
    if data.get("guild_ranks"):
        meta["ranks"] = sorted(
            [(r["idx"], r["label"], r["minRep"]) for r in data["guild_ranks"]],
            key=lambda t: t[2],
        )
    if data.get("capstones"):
        meta["capstones"] = [
            {"key": c["key"], "cv": c["achievedCv"], "label": c["label"],
             "requires": list(c.get("requires", [])), "bonus": c.get("bonus", 0.0)}
            for c in data["capstones"]
        ]
    if data.get("achievements"):
        meta["ach_titles"] = {a["cv"]: a["title"] for a in data["achievements"]}
    return meta


def _rank_for_rep(rep: int, ranks: list) -> tuple:
    """rep -> (current_label, current_min, next_label, next_min).

    ranks is sorted ascending by minRep; next_* is None at the top rank."""
    cur_label, cur_min = ranks[0][1], ranks[0][2]
    nxt_label, nxt_min = None, None
    for _idx, label, minrep in ranks:
        if rep >= minrep:
            cur_label, cur_min = label, minrep
        else:
            nxt_label, nxt_min = label, minrep
            break
    return cur_label, cur_min, nxt_label, nxt_min


def _activity(last_logout) -> str:
    """Recency dot from a last_logout datetime (or None)."""
    if not last_logout:
        return "⚪ Away"
    try:
        days = (datetime.utcnow() - last_logout).total_seconds() / 86400.0
    except Exception:  # noqa: BLE001
        return "⚪ Away"
    if days < 1:
        return "🟢 Active today"
    if days < 7:
        return "🟢 Active this week"
    if days < 31:
        return "🟡 Seen this month"
    return "⚪ Away"


def _badges(p: dict, meta: dict) -> list:
    """Achievement-style chips for the profile header."""
    chips = []
    earned = p.get("capstones", set())
    for c in meta["capstones"]:
        if c["key"] in earned:
            chips.append(("🏆 " if c["key"] == "apex" else "🥇 ") + c["label"])
    gm = p.get("grandmaster_count", 0)
    if gm:
        chips.append(f"👑 Grandmaster ×{gm}" if gm > 1 else "👑 Grandmaster")
    asc = p.get("ascensions", 0)
    if asc:
        chips.append(f"⭐ {asc} Ascension" + ("s" if asc != 1 else ""))
    jobs99 = sum(1 for col in JOB_COLS if p["jobs"][col] >= 99)
    if jobs99:
        chips.append(f"💪 {jobs99} job" + ("s" if jobs99 != 1 else "") + " @99")
    return chips


def _next_step(p: dict, meta: dict) -> str:
    """A single recommended next action that follows the server's progression
    spine: level cap -> Hunting League -> guild capstones -> Prestige."""
    jobs99 = sum(1 for col in JOB_COLS if p["jobs"][col] >= 99)
    if jobs99 == 0:
        best = max(p["jobs"].values()) if p["jobs"] else 1
        return (f"**Hit level 99.** Your highest job is {best}/99 — cap a job to "
                "unlock the Hunting League at Reisenjima Henge.")
    if p["hl_tier"] <= 0:
        return ("**Enter the Hunting League.** Talk to the Hunt Master at "
                "Reisenjima Henge to register and start Rank I.")
    if p["hl_tier"] < 5:
        return (f"**Push to Hunting League Rank {p['hl_tier'] + 1}.** "
                f"You're Rank {p['hl_tier']}/5 — keep clearing the tier roster to rank up.")

    # Rank V capped — chase guild capstones next.
    guild_rep = p.get("guild_rep", {})
    label_for = {k: l for k, l, _ in meta["guilds"]}
    at_gm = {k: guild_rep.get(k, 0) >= _GRANDMASTER_REP for k, _, _ in meta["guilds"]}
    earned = p.get("capstones", set())
    for c in meta["capstones"]:
        if c["key"] in earned:
            continue
        pct = int(round(c["bonus"] * 100))
        missing = [label_for.get(k, k) for k in c["requires"] if not at_gm.get(k, False)]
        if missing:
            return (f"**Chase the {c['label']} title** (+{pct}% marks). "
                    f"Reach Grandmaster in: {', '.join(missing)}.")
        return (f"**Claim {c['label']}** (+{pct}% marks) — you're at Grandmaster "
                "everywhere it needs; the title locks in on your next qualifying kill.")

    # All capstones earned — Prestige.
    if p.get("ascensions", 0) == 0:
        return ("**Begin your first Ascension.** You've maxed the Hunting League "
                "and every guild — talk to the Prestige NPC to reset a job for "
                "permanent, account-wide power.")
    return ("**Keep ascending.** You've cleared the core progression spine — "
            f"stack more Ascensions ({p['ascensions']} so far) and chase speed records.")


def _quick_summary(profile: dict) -> str:
    """One-line highlights for the index table."""
    bits = []
    caps = profile.get("capstones", set())
    if "apex" in caps:
        bits.append("🏆 Apex")
    elif "trinity" in caps:
        bits.append("🥇 Trinity")
    if profile["hl_tier"]:
        bits.append(f"HL Rank {profile['hl_tier']}")
    if profile["augment_mastery"]:
        bits.append(f"Sage Rank {profile['augment_mastery']}")
    jobs_at_99 = sum(1 for col in JOB_COLS if profile["jobs"][col] >= 99)
    if jobs_at_99:
        bits.append(f"{jobs_at_99} jobs@99")
    asc = profile.get("ascensions", 0)
    if asc:
        bits.append(f"⭐{asc}")
    return " · ".join(bits) or "—"


def _render_guild_ranks(p: dict, meta: dict) -> list:
    """Guild standing table — skipped entirely for characters with no rep."""
    guild_rep = p.get("guild_rep", {})
    if not any(guild_rep.get(k, 0) > 0 for k, _, _ in meta["guilds"]):
        return []
    lines = [
        "## Guild standing",
        "",
        "Reputation with each Hunters' Guild sets your rank, and rank amplifies "
        "the marks that guild pays out. Grandmaster (100,000 rep) is the cap.",
        "",
        "| Guild | Rank | Reputation | To next rank |",
        "|---|---|---:|---|",
    ]
    for k, label, _ in meta["guilds"]:
        rep = guild_rep.get(k, 0)
        _cl, _cm, nxt_label, nxt_min = _rank_for_rep(rep, meta["ranks"])
        progress = "**maxed**" if nxt_min is None else f"{nxt_min - rep:,} to {nxt_label}"
        lines.append(f"| {label} | {_cl} | {rep:,} | {progress} |")
    lines.append("")
    return lines


def _render_rebirth(p: dict) -> list:
    """Job Rebirth section — skipped if the char has never reborn a job."""
    counts = p.get("rebirth_counts", {})
    total  = p.get("rebirth_total", 0)
    if not total:
        return []
    lines = [
        "## Job Rebirth",
        "",
        f"- **Total rebirths:** {total}",
    ]
    parts = [
        f"{JOB_ABBR.get(j, f'#{j}')} ×{counts[j]}"
        for j in sorted(counts) if counts[j] > 0
    ]
    if parts:
        lines.append(f"- **By job:** {' · '.join(parts)}")
    lines.append("")
    return lines


def _render_prestige(p: dict) -> list:
    """Prestige / Ascension section — skipped if the char has never ascended."""
    asc = p.get("ascensions", 0)
    levels = p.get("prestige_levels", {})
    if not asc and not levels:
        return []
    lines = [
        "## Prestige",
        "",
        f"- **Total Ascensions:** {asc}",
    ]
    parts = [f"{JOB_ABBR.get(j, f'#{j}')} P{levels[j]}" for j in sorted(levels) if levels[j] > 0]
    if parts:
        lines.append(f"- **Per-job prestige:** {' · '.join(parts)}")
    lines.append("")
    return lines


def _render_achievements(p: dict, meta: dict) -> list:
    """Achievement roll-up — skipped if none earned."""
    earned = p.get("achievements", set())
    names = [title for cv, title in meta["ach_titles"].items() if cv in earned]
    if not names:
        return []
    return [
        "## Achievements",
        "",
        f"**{len(names)}** unlocked — " + " · ".join(names) + ".",
        "",
    ]


def _load_profile(cur, charid: int, base: dict, meta: dict) -> dict:
    """Augment a base char row with everything we need for the profile.

    Each query is independently guarded so one missing table (e.g. an empty
    char_history row) doesn't sink the whole character."""
    profile: dict = dict(base)

    # Per-job levels
    cur.execute(
        f"SELECT {', '.join(JOB_COLS)} FROM char_jobs WHERE charid = %s",
        (charid,),
    )
    row = cur.fetchone()
    profile["jobs"] = dict(zip(JOB_COLS, row)) if row else {c: 0 for c in JOB_COLS}

    # Current main/sub
    cur.execute(
        "SELECT mjob, sjob, mlvl, slvl FROM char_stats WHERE charid = %s",
        (charid,),
    )
    row = cur.fetchone()
    profile["mjob"], profile["sjob"], profile["mlvl"], profile["slvl"] = row or (0, 0, 1, 1)

    # Combat history
    cur.execute(
        "SELECT enemies_defeated, times_knocked_out, spells_cast, "
        "       battles_fought, distance_travelled "
        "  FROM char_history WHERE charid = %s",
        (charid,),
    )
    row = cur.fetchone()
    if row:
        (profile["enemies_defeated"], profile["deaths"], profile["spells_cast"],
         profile["battles_fought"], profile["distance"]) = row
    else:
        profile.update(enemies_defeated=0, deaths=0, spells_cast=0,
                       battles_fought=0, distance=0)

    # Pull all relevant CharVars in one round trip. The fixed list covers the
    # known progression vars; guild-rep and capstone-title varnames come from
    # the catalog so they can't drift from the live Lua.
    fixed_vars = [
        'HL_Tier', 'HL_Points', 'HL_Points_Lifetime',
        'Augment_Count', 'Augment_Mastery', 'Augment_Affinities',
        'Custom_NM_Kills',
        'RF_AF_Marks', 'RF_Relic_Marks', 'RF_Empy_Marks',
        'RF_AF_Marks_Lifetime', 'RF_Relic_Marks_Lifetime', 'RF_Empy_Marks_Lifetime',
        'First99_At', 'HL_FirstKill_At', 'HL_RankVKill_At', 'Augment_Archon_At',
        'Prestige_Ascensions_Total',
    ]
    want_vars = fixed_vars \
        + [repcv for _, _, repcv in meta["guilds"]] \
        + [c["cv"] for c in meta["capstones"]]
    placeholders = ", ".join(["%s"] * len(want_vars))
    cur.execute(
        f"SELECT varname, value FROM char_vars "
        f"WHERE charid = %s AND varname IN ({placeholders})",
        (charid, *want_vars),
    )
    cv = {name: int(val) for name, val in cur.fetchall()}
    profile["hl_tier"]            = cv.get("HL_Tier", 0)
    profile["hl_points"]          = cv.get("HL_Points", 0)
    profile["hl_points_lifetime"] = cv.get("HL_Points_Lifetime", 0)
    profile["augment_count"]      = cv.get("Augment_Count", 0)
    profile["augment_mastery"]    = cv.get("Augment_Mastery", 0)
    profile["affinities_bits"]    = _bit_count(cv.get("Augment_Affinities", 0))
    profile["custom_nm_kills"]    = cv.get("Custom_NM_Kills", 0)
    profile["rf_af"]              = cv.get("RF_AF_Marks", 0)
    profile["rf_relic"]           = cv.get("RF_Relic_Marks", 0)
    profile["rf_empy"]            = cv.get("RF_Empy_Marks", 0)
    profile["rf_af_lt"]           = cv.get("RF_AF_Marks_Lifetime", 0)
    profile["rf_relic_lt"]        = cv.get("RF_Relic_Marks_Lifetime", 0)
    profile["rf_empy_lt"]         = cv.get("RF_Empy_Marks_Lifetime", 0)
    profile["first_99_at"]        = cv.get("First99_At", 0)
    profile["hl_first_at"]        = cv.get("HL_FirstKill_At", 0)
    profile["hl_rankv_at"]        = cv.get("HL_RankVKill_At", 0)
    profile["archon_at"]          = cv.get("Augment_Archon_At", 0)
    profile["ascensions"]         = cv.get("Prestige_Ascensions_Total", 0)

    # Guild reputation keyed by guild key, plus a Grandmaster tally for badges.
    profile["guild_rep"] = {k: cv.get(repcv, 0) for k, _, repcv in meta["guilds"]}
    profile["grandmaster_count"] = sum(
        1 for v in profile["guild_rep"].values() if v >= _GRANDMASTER_REP
    )
    # Capstone titles earned (the title CharVar is set to 1 when awarded).
    profile["capstones"] = {c["key"] for c in meta["capstones"] if cv.get(c["cv"], 0) > 0}

    # Per-job prestige levels (Prestige_Level_<jobId> = completed ascensions).
    cur.execute(
        "SELECT varname, value FROM char_vars "
        " WHERE charid = %s AND varname LIKE 'Prestige_Level_%%' AND value > 0",
        (charid,),
    )
    prestige_levels: dict = {}
    for name, val in cur.fetchall():
        try:
            prestige_levels[int(name.rsplit("_", 1)[1])] = int(val)
        except (ValueError, IndexError):
            continue
    profile["prestige_levels"] = prestige_levels

    # Per-job rebirth counts (Rebirth_Count_<jobId>).
    cur.execute(
        "SELECT varname, value FROM char_vars "
        " WHERE charid = %s AND varname LIKE 'Rebirth_Count_%%' AND value > 0",
        (charid,),
    )
    rebirth_counts: dict = {}
    for name, val in cur.fetchall():
        try:
            rebirth_counts[int(name.rsplit("_", 1)[1])] = int(val)
        except (ValueError, IndexError):
            continue
    profile["rebirth_counts"] = rebirth_counts
    profile["rebirth_total"]  = sum(rebirth_counts.values())

    # Achievements earned (ACH_<id> CharVar set > 0).
    cur.execute(
        "SELECT varname FROM char_vars "
        " WHERE charid = %s AND varname LIKE 'ACH_%%' AND value > 0",
        (charid,),
    )
    profile["achievements"] = {row[0] for row in cur.fetchall()}

    # Distinct NM stamps (NMKilled_<groupId>)
    cur.execute(
        "SELECT COUNT(*) FROM char_vars "
        " WHERE charid = %s AND varname LIKE 'NMKilled_%%' AND value > 0",
        (charid,),
    )
    profile["distinct_nms"] = int(cur.fetchone()[0])

    # Trust spells learned (group=8 in spell_list)
    cur.execute(
        """
        SELECT COUNT(DISTINCT cs.spellid)
          FROM char_spells cs
          JOIN spell_list sl ON sl.spellid = cs.spellid AND sl.`group` = 8
         WHERE cs.charid = %s
        """,
        (charid,),
    )
    profile["trusts"] = int(cur.fetchone()[0])

    return profile


def _render_profile(p: dict, creation_unix: int, meta: dict) -> str:
    """Build the markdown for one character's profile page."""
    nation = NATIONS.get(p["nation"], "Wanderer")
    age_seconds = max(0, int(datetime.utcnow().timestamp()) - creation_unix) if creation_unix else 0
    age_display = _format_duration(age_seconds) if age_seconds else "—"
    last_seen = p["last_logout"].strftime("%Y-%m-%d") if p["last_logout"] else "—"
    created = p["timecreated"].strftime("%Y-%m-%d") if p["timecreated"] else "—"
    playtime_h = p["playtime"] // 3600
    main = f"{JOB_ABBR.get(p['mjob'], '?')} {p['mlvl']}" if p["mjob"] else "—"
    sub = f"{JOB_ABBR.get(p['sjob'], '—')} {p['slvl']}" if p["sjob"] else "—"

    lines = [
        f"# {p['charname']}",
        "",
        f"**{nation} citizen** · {_activity(p['last_logout'])} · Created {created} · "
        f"Last seen {last_seen} · Character age {age_display}",
        "",
    ]
    badges = _badges(p, meta)
    if badges:
        lines += [" ".join(f"`{b}`" for b in badges), ""]
    lines += [
        "!!! tip \"Recommended next step\"",
        f"    {_next_step(p, meta)}",
        "",
        "## At a glance",
        "",
        "| | |",
        "|---|---|",
        f"| Main job | **{main}** |",
        f"| Sub job | {sub} |",
        f"| Time played | {playtime_h}h |",
        f"| Enemies defeated | {p['enemies_defeated']:,} |",
        f"| Deaths | {p['deaths']:,} |",
        "",
        "## Job levels",
        "",
        "| Job | Lv | Job | Lv |",
        "|---|---:|---|---:|",
    ]
    # Two-column job table — looks nicer than a single tall column.
    half = len(JOB_COLS) // 2
    left, right = JOB_COLS[:half], JOB_COLS[half:]
    for lcol, rcol in zip(left, right):
        ll, rl = p["jobs"][lcol], p["jobs"][rcol]
        lstr = f"**{JOB_ABBR[JOB_COLS.index(lcol) + 1]}**" if ll >= 99 else JOB_ABBR[JOB_COLS.index(lcol) + 1]
        rstr = f"**{JOB_ABBR[JOB_COLS.index(rcol) + 1]}**" if rl >= 99 else JOB_ABBR[JOB_COLS.index(rcol) + 1]
        lv_l = f"**{ll}**" if ll >= 99 else str(ll)
        lv_r = f"**{rl}**" if rl >= 99 else str(rl)
        lines.append(f"| {lstr} | {lv_l} | {rstr} | {lv_r} |")
    lines.append("")

    # Hunting League
    lines += [
        "## Hunting League",
        "",
        f"- **Rank:** {p['hl_tier']} / 5",
        f"- **Marks (current):** {p['hl_points']:,}",
        f"- **Marks (lifetime):** {p['hl_points_lifetime']:,}",
        f"- **Distinct NMs slain:** {p['distinct_nms']}",
        f"- **Total NM kills:** {p['custom_nm_kills']:,}",
        "",
    ]

    # Guild standing (catalog-driven; skipped for chars with no rep)
    lines += _render_guild_ranks(p, meta)

    # Augment Sage
    lines += [
        "## Augment Sage",
        "",
        f"- **Mastery rank:** {p['augment_mastery']} / 5",
        f"- **Augments crafted:** {p['augment_count']:,}",
        f"- **NM Affinities:** {p['affinities_bits']} / 13",
        "",
    ]

    # Reforge
    lines += [
        "## Reforge",
        "",
        "| Track | Current | Lifetime |",
        "|---|---:|---:|",
        f"| AF | {p['rf_af']:,} | {p['rf_af_lt']:,} |",
        f"| Relic | {p['rf_relic']:,} | {p['rf_relic_lt']:,} |",
        f"| Empyrean | {p['rf_empy']:,} | {p['rf_empy_lt']:,} |",
        "",
    ]

    # Job Rebirth (skipped for chars who've never reborn)
    lines += _render_rebirth(p)

    # Prestige / Ascension (skipped for chars who've never ascended)
    lines += _render_prestige(p)

    # Collections
    lines += [
        "## Collections",
        "",
        f"- **Trusts learned:** {p['trusts']}",
        "",
    ]

    # Achievements (catalog titles; skipped if none earned)
    lines += _render_achievements(p, meta)

    # Records (only show ones that have fired)
    records = []
    if p["first_99_at"] and creation_unix:
        records.append(("Fastest 1 → 99", p["first_99_at"] - creation_unix))
    if p["hl_first_at"] and p["hl_rankv_at"]:
        records.append(("HL Rank I → V", p["hl_rankv_at"] - p["hl_first_at"]))
    if p["archon_at"] and creation_unix:
        records.append(("Augment Archon", p["archon_at"] - creation_unix))
    if records:
        lines += [
            "## Speed records",
            "",
            "| Record | Time |",
            "|---|---:|",
        ]
        for label, secs in records:
            lines.append(f"| {label} | {_format_duration(max(0, secs))} |")
        lines.append("")
    else:
        lines += [
            "## Speed records",
            "",
            "_No locked-in speed records yet. They'll appear here once you trip the milestone events (level a job to 99, kill any Hunting League NM, hit Augment Archon)._",
            "",
        ]

    lines += [
        "---",
        "",
        "_This profile updates automatically from live server data. To opt out, use "
        "`!optout` in-game — your page (and entry on the [Leaderboards](../leaderboards.md)) is removed on the next refresh._",
        "",
    ]
    return "\n".join(lines)


def _render_index(rows: list[dict]) -> str:
    lines = [
        "# Player Profiles",
        "",
        f"{len(rows)} characters with public profiles on Legendary. "
        "Click a name for the full breakdown — jobs, hunt league progress, "
        "augment mastery, gear/play stats, speed records.",
        "",
        "!!! tip \"Want to hide your profile?\"",
        "    Set `Leaderboard_OptOut = 1` on your character and your page is removed on the next site refresh.",
        "",
        "| Character | Nation | Main | Time | Highlights |",
        "|---|---|---|---:|---|",
    ]
    # Sort by time played desc for the index — most-engaged at the top.
    for p in sorted(rows, key=lambda r: r["playtime"], reverse=True):
        slug = _slug(p["charname"])
        main = (f"{JOB_ABBR.get(p['mjob'], '?')} {p['mlvl']}"
                if p["mjob"] else "—")
        nation = NATIONS.get(p["nation"], "Wanderer")
        playtime_h = p["playtime"] // 3600
        lines.append(
            f"| [{p['charname']}]({slug}.md) | {nation} | {main} | {playtime_h}h | {_quick_summary(p)} |"
        )
    lines += [
        "",
        "---",
        "",
        "_The index re-sorts on each refresh by time played. The actual profile pages live one folder deeper and update with the same cadence as the [Leaderboards](../leaderboards.md)._",
        "",
    ]
    return "\n".join(lines)


def generate(repo_root: Path, docs_dir: Path) -> None:
    conn = connect(repo_root)
    if conn is None:
        print("[player_profiles] skip: no DB connection (LEGENDARY_LIVE_ROOT unset / DB unreachable)")
        return

    meta = _load_meta(repo_root)
    profiles_dir = docs_dir / _PROFILES_SUBDIR
    profiles_dir.mkdir(parents=True, exist_ok=True)

    cur = conn.cursor()
    try:
        cur.execute(
            """
            SELECT c.charid, c.charname, c.nation, c.playtime,
                   c.timecreated, c.last_logout
              FROM chars c
         LEFT JOIN char_vars opt ON opt.charid = c.charid
                                AND opt.varname = 'Leaderboard_OptOut'
             WHERE (opt.value IS NULL OR opt.value = 0)
          ORDER BY c.charname
            """
        )
        base_rows = cur.fetchall()

        # Hydrate each char with everything else we want to show.
        profiles: list[dict] = []
        for charid, charname, nation, playtime, timecreated, last_logout in base_rows:
            base = {
                "charid": charid, "charname": charname, "nation": nation,
                "playtime": playtime, "timecreated": timecreated,
                "last_logout": last_logout,
            }
            profiles.append(_load_profile(cur, charid, base, meta))
    finally:
        cur.close()
        conn.close()

    # Track which slug files are "ours" so we can prune stale ones (renames,
    # opt-outs). Don't touch the index file itself.
    wanted = {f"{_slug(p['charname'])}.md" for p in profiles}
    wanted.add("index.md")
    for existing in profiles_dir.glob("*.md"):
        if existing.name not in wanted:
            existing.unlink()

    for p in profiles:
        creation_unix = int(p["timecreated"].timestamp()) if p["timecreated"] else 0
        (profiles_dir / f"{_slug(p['charname'])}.md").write_text(
            _render_profile(p, creation_unix, meta), encoding="utf-8"
        )

    (profiles_dir / "index.md").write_text(_render_index(profiles), encoding="utf-8")

    print(f"[player_profiles] {len(profiles)} profile(s) written to {profiles_dir.relative_to(docs_dir.parent)}")
