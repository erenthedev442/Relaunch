"""Render live player leaderboards onto docs/community/leaderboards.md.

Reads `char_vars` from the live database and emits one DOCGEN marker
block per board. Boards are seeded from the CharVars custom modules
already track:

  Augment_Count   — set by Augment_Moogle on every successful augment
  Augment_Mastery — set by Augment_Sage on rank-up
  HL_Points       — Hunting League lifetime points
  HL_Tier         — Hunting League highest tier reached
  RF_AF_Marks     — Reforge AF marks (current balance)
  RF_Relic_Marks  — Reforge Relic marks (current balance)
  RF_Empy_Marks   — Reforge Empyrean marks (current balance)

Players can opt out by setting CharVar `Leaderboard_OptOut = 1` (the
generator filters them at query time).

The module no-ops silently if the database is unreachable — running
`tools/docgen/generate.py` on CI (no LEGENDARY_LIVE_ROOT) skips it
without overwriting the previously-published markdown.
"""
from __future__ import annotations

import datetime as _dt
import re
from pathlib import Path

from tools.docgen._db import connect
from tools.docgen._markers import write_between_markers


_TOP_N = 10


def _profile_slug(name: str) -> str:
    """Charname -> profile filename slug. MUST match player_profiles._slug
    so leaderboard links point at real pages (which are written under
    docs/community/players/<slug>.md)."""
    s = re.sub(r"[^A-Za-z0-9]+", "_", name).strip("_").lower()
    return s or "anon"


def _profile_link(name: str) -> str:
    """Wrap a charname in a markdown link to that character's profile page.
    leaderboards.md lives at docs/community/leaderboards.md, so the relative
    path to docs/community/players/<slug>.md is just `players/<slug>.md`."""
    return f"[{name}](players/{_profile_slug(name)}.md)"


# Each entry: (marker_id, heading, blurb, query)
# `query` is parameterless and must return rows shaped as (name, value)
# with the leaderboard's intended sort order.
_SINGLE_VAR_BOARDS = [
    {
        "marker":  "lb-augments",
        "heading": "Most Augments Crafted",
        "blurb":   "Lifetime count of successful Augment Moogle trades. "
                   "Every confirmed trade bumps this by 1, regardless of "
                   "how many catalysts were used.",
        "var":     "Augment_Count",
        "unit":    "augments",
    },
    {
        "marker":  "lb-hl-tier",
        "heading": "Hunting League — Highest Tier",
        "blurb":   "Top tier any character has unlocked in the Hunting "
                   "League progression. Ties broken by HL points.",
        "var":     "HL_Tier",
        "unit":    "tier",
        "tiebreaker": "HL_Points",
    },
    {
        "marker":  "lb-hl-points",
        "heading": "Hunting League — Lifetime Points",
        "blurb":   "Points earned across all Hunting League NM kills. "
                   "Lifetime total, not current spendable balance.",
        "var":     "HL_Points",
        "unit":    "pts",
    },
    {
        "marker":  "lb-empy-marks",
        "heading": "Reforge — Empyrean Marks (Current Balance)",
        "blurb":   "Current Empyrean Marks held. Earned from Abyssea NM "
                   "spawns at the Reforge Spawner, spent at the Reforge "
                   "Vendor for +1/+2/+3 upgrades.",
        "var":     "RF_Empy_Marks",
        "unit":    "marks",
    },
    {
        "marker":  "lb-nm-kills",
        "heading": "Top NM Slayers",
        "blurb":   "Total custom NMs defeated across the Hunting League "
                   "and Reforge Spawner. Each successful kill counts once; "
                   "the counter never decreases.",
        "var":     "Custom_NM_Kills",
        "unit":    "kills",
    },
    {
        "marker":  "lb-hl-lifetime",
        "heading": "Hunting League — Marks Earned (Lifetime)",
        "blurb":   "Cumulative Hunt Marks earned over the character's "
                   "lifetime — does NOT decrease when marks are spent. "
                   "Big spenders surface here even after they've cashed out.",
        "var":     "HL_Points_Lifetime",
        "unit":    "marks",
    },
    # ===== Hunter's Guild reputation, one board per guild ============
    {
        "marker":  "lb-guild-af",
        "heading": "AF Hunters' Guild — Top Reputation",
        "blurb":   "Cumulative AF Hunters' Guild rep. Earned 1:1 from base "
                   "AF Marks per Reforge Sky-God kill. Apprentice → Grandmaster "
                   "at 100,000 rep. See [Hunter's Guild](../progression/hunters-guild.md) "
                   "for the full rank ladder + amplifier table.",
        "var":     "Guild_AF_Rep",
        "unit":    "rep",
    },
    {
        "marker":  "lb-guild-relic",
        "heading": "Relic Hunters' Guild — Top Reputation",
        "blurb":   "Cumulative Relic Hunters' Guild rep. Earned 1:1 from base "
                   "Relic Marks per Reforge Unity-NM kill.",
        "var":     "Guild_Relic_Rep",
        "unit":    "rep",
    },
    {
        "marker":  "lb-guild-empy",
        "heading": "Empyrean Hunters' Guild — Top Reputation",
        "blurb":   "Cumulative Empyrean Hunters' Guild rep. Earned 1:1 from "
                   "base Empy Marks per Reforge Abyssea-NM kill.",
        "var":     "Guild_Empy_Rep",
        "unit":    "rep",
    },
    {
        "marker":  "lb-guild-hl",
        "heading": "League Hunters' Guild — Top Reputation",
        "blurb":   "Cumulative League Hunters' Guild rep. Earned 1:1 from "
                   "base Hunt Marks per HL kill.",
        "var":     "Guild_HL_Rep",
        "unit":    "rep",
    },
    {
        "marker":  "lb-weekly-sweeps",
        "heading": "Most Weekly Hunt Sweeps",
        "blurb":   "How many distinct weeks this character has cleared ALL 5 "
                   "Weekly Hunt Board objectives. The consistency metric — "
                   "doesn't reward who hits the cap first, rewards who keeps "
                   "showing up week after week.",
        "var":     "WH_AllCleared_Lifetime",
        "unit":    "sweeps",
    },
    # ===== The Gauntlet ==============================================
    {
        "marker":  "lb-gauntlet-clears",
        "heading": "The Gauntlet — Most Clears",
        "blurb":   "Total completions of The Gauntlet — defeating Shinryu on the 10th floor. "
                   "Each clear grants 500M gil and 50,000 Paragon Points; the counter never "
                   "resets. Multiple clears mean maximum dedication (or a very large bank).",
        "var":     "Gauntlet_Clears",
        "unit":    "clears",
    },
    # ===== Endless Tower =============================================
    {
        "marker":  "lb-tower-floor",
        "heading": "Endless Tower — Highest Floor",
        "blurb":   "Deepest floor ever reached in the Endless Tower. Each floor is a harder "
                   "boss fight. The record is permanent — locked to the moment you hit it. "
                   "Floor 50 grants the Prime Weapon Trial 2 clear.",
        "var":     "Tower_Best_Floor",
        "unit":    "floor",
    },
    # ===== Prestige & Paragon ========================================
    {
        "marker":  "lb-prestige-total",
        "heading": "Prestige Ascensions (Total)",
        "blurb":   "Total Ascension completions across all jobs. Each Ascension resets a "
                   "job's trial-NM circuit for permanent stat bonuses — stacking indefinitely. "
                   "The grind metric for committed Prestige runners.",
        "var":     "Prestige_Total_Ascensions",
        "unit":    "ascensions",
    },
    {
        "marker":  "lb-paragon-points",
        "heading": "Paragon Points (Current Balance)",
        "blurb":   "Unspent Paragon Points banked from Apex Trials and Gauntlet clears. "
                   "Spent at the Paragon NPC on levels, perks, and the Daily Might buff. "
                   "Big hoarders appear here; big spenders climb the Paragon Level board instead.",
        "var":     "Paragon_Points",
        "unit":    "pts",
    },
    # ===== Infamy ====================================================
    {
        "marker":  "lb-infamy-lifetime",
        "heading": "Infamy Earned (Lifetime)",
        "blurb":   "Cumulative Infamy earned across all endgame content —"
                   "doesn't decrease when spent at the Infamy Vendor. The "
                   "raw grind metric. Includes base reward + speed bonuses.",
        "var":     "Infamy_Lifetime",
        "unit":    "infamy",
    },
    {
        "marker":  "lb-infamy-balance",
        "heading": "Infamy (Current Balance)",
        "blurb":   "Infamy currently held — drops when you buy from the "
                   "Infamy Vendor. The hoarder index. Big spenders show up "
                   "on the Lifetime board, not this one.",
        "var":     "Infamy",
        "unit":    "infamy",
    },
]


# Job Rebirth board — SUM of Rebirth_Count_* across all jobs per character.
_JOB_REBIRTH_BOARD = {
    "marker":  "lb-job-rebirths",
    "heading": "Job Rebirths — Total Resets",
    "blurb":   "Total number of job rebirths across all jobs combined. "
               "Each rebirth wipes a job back to level 1 and earns Rebirth Points "
               "for permanent per-job stat boosts. The grind metric for committed "
               "power-grinders.",
    "pattern": "Rebirth_Count_%",
    "unit":    "rebirths",
}


# Boards that count CharVars matching a name pattern (e.g. NMKilled_%).
# Each row is one set/collection — the score is "how many bits/items".
_PATTERN_COUNT_BOARDS = [
    {
        "marker":  "lb-nm-encyclopedia",
        "heading": "NM Encyclopedia — Distinct NMs Slain",
        "blurb":   "Number of distinct custom NMs each character has "
                   "personally killed at least once. Each unique kill "
                   "stamps a CharVar; this counts the stamps. The completionist "
                   "board for the Hunting League roster.",
        "pattern": "NMKilled_%",
        "unit":    "NMs",
    },
    {
        "marker":  "lb-trusts",
        "heading": "Trust Roll Call — Distinct Trusts Learned",
        "blurb":   "Count of distinct Trust alter-egos the character has "
                   "learned. Read from the char_spells table joined to the "
                   "Trust spell group (group 8) — no extra tracking needed.",
        "kind":    "trusts_learned",  # special-cased in the dispatcher
        "unit":    "trusts",
    },
]


# Boards that read from non-`char_vars` tables. Each has a custom query.
# Achievers boards: roll-call style (list of names, no value column).
# Used for one-time capstone titles where ranking by "value=1" is silly
# but listing who's earned the title is the whole point.
_ACHIEVERS_BOARDS = [
    {
        "marker":  "lb-trinity-hunters",
        "heading": "Trinity Hunters",
        "blurb":   "Roll call of players who have reached Grandmaster in all "
                   "three Reforge Hunter's Guilds (AF / Relic / Empy). The "
                   "first major capstone in the Hunter's Guild system — "
                   "+25% bonus to those marks.",
        "var":     "Title_Trinity_Hunter",
    },
    {
        "marker":  "lb-apex-hunters",
        "heading": "Apex Hunters",
        "blurb":   "Roll call of players who have reached Grandmaster in ALL "
                   "FOUR Hunter's Guilds (AF / Relic / Empy / League). The "
                   "highest server achievement — +50% bonus to ALL marks. "
                   "If this list is empty, you could be on it.",
        "var":     "Title_Apex_Hunter",
    },
]


_TABLE_BOARDS = [
    {
        "marker":  "lb-job-mastery",
        "heading": "Job Mastery Champion",
        "blurb":   "How many of the 22 jobs the character has at level 99. "
                   "Ties broken by the sum of all job levels (so a 99/99/99/95 "
                   "edges out a 99/99/99/1). The well-rounded badge.",
        "kind":    "job_mastery",
        "unit":    "jobs at 99",
    },
    {
        "marker":  "lb-playtime",
        "heading": "Most Time Played",
        "blurb":   "Hours the character has spent online. Read from "
                   "`chars.playtime` (seconds). Brag responsibly.",
        "kind":    "playtime",
        "unit":    "hours",
    },
    {
        "marker":  "lb-deaths",
        "heading": "Most Deaths",
        "blurb":   "Times the character has been knocked unconscious. "
                   "On Legendary you lose 3× retail EXP per death — wear it "
                   "as a badge of honor (or shame).",
        "kind":    "deaths",
        "unit":    "deaths",
    },
]


# Speed boards — race against the clock. Each tracks two timestamps
# (start, end) and reports the delta. The "anchor" form uses
# `chars.timecreated` as the start; the "two-var" form uses two CharVars.
_SPEED_BOARDS = [
    {
        "marker":  "lb-fastest-99",
        "heading": "Fastest 1 → 99 (Any Job)",
        "blurb":   "Time from character creation to first reaching level "
                   "99 on any job. Locked in the moment it fires. Records "
                   "made on this server, by this version of you.",
        "kind":    "speed_from_creation",
        "end_var": "First99_At",
    },
    {
        "marker":  "lb-fastest-hl",
        "heading": "Fastest Hunting League Rank I → Rank V",
        "blurb":   "Time from your first Hunting League kill (any tier) to "
                   "your first Tier V kill. The whole league run, end to end.",
        "kind":    "speed_two_var",
        "start_var": "HL_FirstKill_At",
        "end_var":   "HL_RankVKill_At",
    },
    {
        "marker":  "lb-fastest-archon",
        "heading": "Fastest Augment Archon",
        "blurb":   "Time from character creation to reaching Augment Sage "
                   "rank 5 (Augment Archon). Encompasses every prerequisite: "
                   "250 lifetime augments, all trophy NMs farmed, every seal "
                   "tier accumulated.",
        "kind":    "speed_from_creation",
        "end_var": "Augment_Archon_At",
    },
]


# Combined Reforge marks (sum across AF + Relic + Empy). Special-case
# because it needs a SUM/GROUP BY, not a single-var lookup.
_COMBINED_REFORGE_BOARD = {
    "marker":  "lb-reforge-total",
    "heading": "Reforge — Combined Marks (AF + Relic + Empy)",
    "blurb":   "Total Reforge marks held across all three currencies, "
               "right now. The Mark Hoarder index.",
    "unit":    "marks",
    "vars":    ("RF_AF_Marks", "RF_Relic_Marks", "RF_Empy_Marks"),
}


# Tiered combat records — 5 categories × 4 mob-level tiers.
# Each tier is a separate CharVar: <category>_T1 through _T4.
# Tiers: T1 = Lv 1–33 | T2 = Lv 34–67 | T3 = Lv 68–99 | T4 = Lv 100+
# Tracked by modules/custom/lua/combat_records.lua (needs one map restart).
_TIER_LABELS = [("T1", "Lv 1–33"), ("T2", "Lv 34–67"), ("T3", "Lv 68–99"), ("T4", "Lv 100+")]

_TIERED_COMBAT_BOARDS = [
    {
        "category": "MaxHeal",
        "heading":  "Highest Single Heal",
        "blurb":    "Largest single cure or healing spell on any target at {tier}. "
                    "Measured at the moment the spell lands. Your best across all tiers "
                    "is shown in-game by The Chronicler NPC.",
        "unit":     "HP healed",
    },
    {
        "category": "MaxNuke",
        "heading":  "Highest Single Nuke",
        "blurb":    "Peak magic damage from a single spell landing on a {tier} mob. "
                    "Magic bursts also count here — the highest burst naturally sets "
                    "this record too.",
        "unit":     "damage",
    },
    {
        "category": "MaxBurst",
        "heading":  "Highest Magic Burst",
        "blurb":    "Largest magic burst damage on a single {tier} mob target. "
                    "Requires matching the right element chain at the right moment — "
                    "the precision record.",
        "unit":     "damage",
    },
    {
        "category": "MaxSC",
        "heading":  "Highest Skillchain",
        "blurb":    "Largest single skillchain damage on a {tier} mob. Triggered via "
                    "weapon skills in the correct order. Records start accumulating "
                    "after the next map rebuild (requires C++ getAddEffectParam).",
        "unit":     "damage",
    },
    {
        "category": "MaxDmg30",
        "heading":  "Most Damage in 30 Seconds",
        "blurb":    "Highest total damage dealt to {tier} mobs in any rolling 30-second "
                    "window, combining weapon skills, magic, and ranged attacks. The "
                    "burst DPS record — reset on zone change.",
        "unit":     "damage",
    },
]


# Lifetime combined Reforge marks (sum across the three _Lifetime
# counters). Never decreases when players spend, so this is the true
# "grind" measure.
_LIFETIME_REFORGE_BOARD = {
    "marker":  "lb-reforge-lifetime",
    "heading": "Reforge — Lifetime Marks Earned",
    "blurb":   "Total marks earned across AF + Relic + Empy tracks, "
               "all-time. Spending doesn't decrease this — it measures "
               "total NM grind, not current wealth.",
    "unit":    "marks",
    "vars":    ("RF_AF_Marks_Lifetime", "RF_Relic_Marks_Lifetime", "RF_Empy_Marks_Lifetime"),
}


def _query_single_var(cur, var: str, tiebreaker: str | None) -> list[tuple[str, int]]:
    """Top _TOP_N characters by a single char_vars row. Respects opt-out.

    Lifetime CharVars never expire, but we filter expiry just in case
    something gets repurposed later.
    """
    if tiebreaker:
        cur.execute(
            """
            SELECT c.charname,
                   cv.value AS primary_val,
                   COALESCE(tb.value, 0) AS tiebreaker_val
              FROM char_vars cv
              JOIN chars c ON c.charid = cv.charid
         LEFT JOIN char_vars tb ON tb.charid = cv.charid AND tb.varname = %s
         LEFT JOIN char_vars opt ON opt.charid = cv.charid AND opt.varname = 'Leaderboard_OptOut'
             WHERE cv.varname = %s
               AND (cv.expiry = 0 OR cv.expiry > UNIX_TIMESTAMP())
               AND cv.value > 0
               AND (opt.value IS NULL OR opt.value = 0)
          ORDER BY cv.value DESC, tiebreaker_val DESC
             LIMIT %s
            """,
            (tiebreaker, var, _TOP_N),
        )
        return [(r[0], r[1]) for r in cur.fetchall()]

    cur.execute(
        """
        SELECT c.charname, cv.value
          FROM char_vars cv
          JOIN chars c ON c.charid = cv.charid
     LEFT JOIN char_vars opt ON opt.charid = cv.charid AND opt.varname = 'Leaderboard_OptOut'
         WHERE cv.varname = %s
           AND (cv.expiry = 0 OR cv.expiry > UNIX_TIMESTAMP())
           AND cv.value > 0
           AND (opt.value IS NULL OR opt.value = 0)
      ORDER BY cv.value DESC
         LIMIT %s
        """,
        (var, _TOP_N),
    )
    return [(r[0], r[1]) for r in cur.fetchall()]


def _query_pattern_sum(cur, pattern: str) -> list[tuple[str, int]]:
    """Top _TOP_N characters by SUM of `value` across vars matching a LIKE pattern.

    Used for Job Rebirth totals (Rebirth_Count_%) where we want the cumulative
    count across all jobs, not just a count of how many vars exist.
    """
    cur.execute(
        """
        SELECT c.charname, SUM(cv.value) AS total
          FROM char_vars cv
          JOIN chars c ON c.charid = cv.charid
     LEFT JOIN char_vars opt ON opt.charid = cv.charid AND opt.varname = 'Leaderboard_OptOut'
         WHERE cv.varname LIKE %s
           AND (cv.expiry = 0 OR cv.expiry > UNIX_TIMESTAMP())
           AND cv.value > 0
           AND (opt.value IS NULL OR opt.value = 0)
      GROUP BY c.charid, c.charname
        HAVING total > 0
      ORDER BY total DESC
         LIMIT %s
        """,
        (pattern, _TOP_N),
    )
    return [(r[0], int(r[1])) for r in cur.fetchall()]


def _query_summed_vars(cur, varnames: tuple[str, ...]) -> list[tuple[str, int]]:
    """Top _TOP_N characters by SUM of `value` across the given var names.

    Used by the combined-current-balance Reforge board and the
    combined-lifetime Reforge board — same shape, different var sets.
    """
    placeholders = ",".join(["%s"] * len(varnames))
    cur.execute(
        f"""
        SELECT c.charname, SUM(cv.value) AS total
          FROM char_vars cv
          JOIN chars c ON c.charid = cv.charid
     LEFT JOIN char_vars opt ON opt.charid = cv.charid AND opt.varname = 'Leaderboard_OptOut'
         WHERE cv.varname IN ({placeholders})
           AND (cv.expiry = 0 OR cv.expiry > UNIX_TIMESTAMP())
           AND (opt.value IS NULL OR opt.value = 0)
      GROUP BY c.charname
        HAVING total > 0
      ORDER BY total DESC
         LIMIT %s
        """,
        (*varnames, _TOP_N),
    )
    return [(r[0], int(r[1])) for r in cur.fetchall()]


def _render_board(heading: str, blurb: str, unit: str, rows: list[tuple[str, int]],
                  value_formatter=None) -> str:
    """Render a top-N board. `value_formatter(value)` is called per row if
    given — used by speed boards to pretty-print seconds as `2d 4h`."""
    lines: list[str] = []
    lines.append(f"### {heading}")
    lines.append("")
    lines.append(f"_{blurb}_")
    lines.append("")
    if not rows:
        lines.append("_No qualifying characters yet — be the first!_")
        return "\n".join(lines)
    lines.append("| Rank | Character | " + unit.capitalize() + " |")
    lines.append("|---:|---|---:|")
    for i, (name, value) in enumerate(rows, start=1):
        medal = {1: "🥇", 2: "🥈", 3: "🥉"}.get(i, str(i))
        display = value_formatter(value) if value_formatter else f"{value:,}"
        lines.append(f"| {medal} | {_profile_link(name)} | {display} |")
    return "\n".join(lines)


def _format_duration(seconds: int) -> str:
    """Seconds → '2d 4h' / '4h 12m' / '12m 30s'. Sized to fit a table cell."""
    if seconds < 60:
        return f"{seconds}s"
    if seconds < 3600:
        m = seconds // 60
        s = seconds % 60
        return f"{m}m {s}s" if s else f"{m}m"
    if seconds < 86400:
        h = seconds // 3600
        m = (seconds % 3600) // 60
        return f"{h}h {m}m" if m else f"{h}h"
    d = seconds // 86400
    h = (seconds % 86400) // 3600
    return f"{d}d {h}h" if h else f"{d}d"


# ---------------------------------------------------------------------------
# Custom query helpers
# ---------------------------------------------------------------------------
def _query_job_mastery(cur) -> list[tuple[str, int]]:
    """Count of jobs at level 99 per character, from char_jobs. Tiebreaker:
    sum of all job levels (the most maxed-and-progressing wins)."""
    job_cols = ("war", "mnk", "whm", "blm", "rdm", "thf", "pld", "drk",
                "bst", "brd", "rng", "sam", "nin", "drg", "smn", "blu",
                "cor", "pup", "dnc", "sch", "geo", "run")
    at99   = " + ".join(f"({c} = 99)" for c in job_cols)
    sumall = " + ".join(job_cols)
    cur.execute(
        f"""
        SELECT c.charname,
               ({at99})   AS jobs_at_99,
               ({sumall}) AS total_levels
          FROM char_jobs cj
          JOIN chars c ON c.charid = cj.charid
     LEFT JOIN char_vars opt ON opt.charid = cj.charid
                            AND opt.varname = 'Leaderboard_OptOut'
         WHERE (opt.value IS NULL OR opt.value = 0)
           AND ({at99}) > 0
      ORDER BY jobs_at_99 DESC, total_levels DESC
         LIMIT %s
        """,
        (_TOP_N,),
    )
    return [(r[0], int(r[1])) for r in cur.fetchall()]


def _query_playtime(cur) -> list[tuple[str, int]]:
    """chars.playtime is in seconds; we display as hours."""
    cur.execute(
        """
        SELECT c.charname, c.playtime
          FROM chars c
     LEFT JOIN char_vars opt ON opt.charid = c.charid
                            AND opt.varname = 'Leaderboard_OptOut'
         WHERE (opt.value IS NULL OR opt.value = 0)
           AND c.playtime > 0
      ORDER BY c.playtime DESC
         LIMIT %s
        """,
        (_TOP_N,),
    )
    return [(r[0], int(r[1] // 3600)) for r in cur.fetchall()]  # seconds → hours


def _query_deaths(cur) -> list[tuple[str, int]]:
    """char_history.times_knocked_out — total deaths."""
    cur.execute(
        """
        SELECT c.charname, h.times_knocked_out
          FROM char_history h
          JOIN chars c ON c.charid = h.charid
     LEFT JOIN char_vars opt ON opt.charid = h.charid
                            AND opt.varname = 'Leaderboard_OptOut'
         WHERE (opt.value IS NULL OR opt.value = 0)
           AND h.times_knocked_out > 0
      ORDER BY h.times_knocked_out DESC
         LIMIT %s
        """,
        (_TOP_N,),
    )
    return [(r[0], int(r[1])) for r in cur.fetchall()]


def _query_gauntlet_all(cur) -> list[tuple[str, int]]:
    """All players who have cleared The Gauntlet (no top-N cap), sorted by clears DESC."""
    cur.execute(
        """
        SELECT c.charname, cv.value
          FROM char_vars cv
          JOIN chars c ON c.charid = cv.charid
     LEFT JOIN char_vars opt ON opt.charid = cv.charid AND opt.varname = 'Leaderboard_OptOut'
         WHERE cv.varname = 'Gauntlet_Clears'
           AND (cv.expiry = 0 OR cv.expiry > UNIX_TIMESTAMP())
           AND cv.value > 0
           AND (opt.value IS NULL OR opt.value = 0)
      ORDER BY cv.value DESC
        """,
    )
    return [(r[0], int(r[1])) for r in cur.fetchall()]


def _query_richest_gil(cur) -> list[tuple[str, int]]:
    """Top _TOP_N characters by current gil balance from chars.gold."""
    cur.execute(
        """
        SELECT c.charname, c.gold
          FROM chars c
     LEFT JOIN char_vars opt ON opt.charid = c.charid AND opt.varname = 'Leaderboard_OptOut'
         WHERE (opt.value IS NULL OR opt.value = 0)
           AND c.gold > 0
      ORDER BY c.gold DESC
         LIMIT %s
        """,
        (_TOP_N,),
    )
    return [(r[0], int(r[1])) for r in cur.fetchall()]


def _query_pattern_count(cur, pattern: str) -> list[tuple[str, int]]:
    """Count of CharVars matching `pattern` (with %% wildcards) per character.
    Used by the NM Encyclopedia board, where each unique kill writes one
    `NMKilled_<id>` CharVar."""
    cur.execute(
        """
        SELECT c.charname, COUNT(*) AS hits
          FROM char_vars cv
          JOIN chars c ON c.charid = cv.charid
     LEFT JOIN char_vars opt ON opt.charid = cv.charid
                            AND opt.varname = 'Leaderboard_OptOut'
         WHERE cv.varname LIKE %s
           AND cv.value > 0
           AND (opt.value IS NULL OR opt.value = 0)
      GROUP BY c.charid, c.charname
        HAVING hits > 0
      ORDER BY hits DESC
         LIMIT %s
        """,
        (pattern, _TOP_N),
    )
    return [(r[0], int(r[1])) for r in cur.fetchall()]


def _query_achievers(cur, var: str) -> list[str]:
    """Return names of all opted-in characters who have CharVar `var` = 1.
    Used for capstone roll-call boards (Trinity / Apex Hunters).
    Sorted alphabetically — we don't track when titles were earned, so
    alphabetical is the least-arbitrary stable order."""
    cur.execute(
        """
        SELECT c.charname
          FROM char_vars cv
          JOIN chars c ON c.charid = cv.charid
     LEFT JOIN char_vars opt ON opt.charid = cv.charid
                            AND opt.varname = 'Leaderboard_OptOut'
         WHERE cv.varname = %s
           AND cv.value = 1
           AND (cv.expiry = 0 OR cv.expiry > UNIX_TIMESTAMP())
           AND (opt.value IS NULL OR opt.value = 0)
      ORDER BY c.charname
        """,
        (var,),
    )
    return [r[0] for r in cur.fetchall()]


def _render_achievers_board(heading: str, blurb: str, names: list[str]) -> str:
    """Roll-call render — just names, no value column. Mirrors the
    single-var board structure (heading + blurb + table) so the page
    looks consistent."""
    lines: list[str] = []
    lines.append(f"### {heading}")
    lines.append("")
    lines.append(f"_{blurb}_")
    lines.append("")
    if not names:
        lines.append("_No achievers yet — be the first to make the list._")
        return "\n".join(lines)
    lines.append("| # | Character |")
    lines.append("|---:|---|")
    for i, name in enumerate(names, start=1):
        lines.append(f"| {i} | {_profile_link(name)} |")
    return "\n".join(lines)


def _query_trusts_learned(cur) -> list[tuple[str, int]]:
    """Distinct trusts learned, via char_spells + spell_list group=8."""
    cur.execute(
        """
        SELECT c.charname, COUNT(DISTINCT cs.spellid) AS trusts
          FROM char_spells cs
          JOIN spell_list sl ON sl.spellid = cs.spellid
                            AND sl.`group` = 8
          JOIN chars c ON c.charid = cs.charid
     LEFT JOIN char_vars opt ON opt.charid = cs.charid
                            AND opt.varname = 'Leaderboard_OptOut'
         WHERE (opt.value IS NULL OR opt.value = 0)
      GROUP BY c.charid, c.charname
        HAVING trusts > 0
      ORDER BY trusts DESC
         LIMIT %s
        """,
        (_TOP_N,),
    )
    return [(r[0], int(r[1])) for r in cur.fetchall()]


def _query_speed_from_creation(cur, end_var: str) -> list[tuple[str, int]]:
    """Speed board with creation timestamp as the start anchor.
    Returns rows as (name, seconds_elapsed) sorted ASC (fastest first)."""
    cur.execute(
        """
        SELECT c.charname,
               (cv.value - UNIX_TIMESTAMP(c.timecreated)) AS duration
          FROM char_vars cv
          JOIN chars c ON c.charid = cv.charid
     LEFT JOIN char_vars opt ON opt.charid = cv.charid
                            AND opt.varname = 'Leaderboard_OptOut'
         WHERE cv.varname = %s
           AND cv.value > 0
           AND (opt.value IS NULL OR opt.value = 0)
           AND cv.value >= UNIX_TIMESTAMP(c.timecreated)
      ORDER BY duration ASC
         LIMIT %s
        """,
        (end_var, _TOP_N),
    )
    return [(r[0], int(r[1])) for r in cur.fetchall()]


def _query_speed_two_var(cur, start_var: str, end_var: str) -> list[tuple[str, int]]:
    """Speed board where both start and end are CharVars (Unix timestamps)."""
    cur.execute(
        """
        SELECT c.charname,
               (e.value - s.value) AS duration
          FROM char_vars s
          JOIN char_vars e ON e.charid = s.charid AND e.varname = %s
          JOIN chars c ON c.charid = s.charid
     LEFT JOIN char_vars opt ON opt.charid = s.charid
                            AND opt.varname = 'Leaderboard_OptOut'
         WHERE s.varname = %s
           AND s.value > 0
           AND e.value > s.value
           AND (opt.value IS NULL OR opt.value = 0)
      ORDER BY duration ASC
         LIMIT %s
        """,
        (end_var, start_var, _TOP_N),
    )
    return [(r[0], int(r[1])) for r in cur.fetchall()]


def _query_maat_best_time(cur) -> list[tuple[str, int]]:
    """Top _TOP_N characters by fastest Maat kill. Maat_Best_Time is stored
    as elapsed seconds from Maat's first engage to his death — lower is better."""
    cur.execute(
        """
        SELECT c.charname, cv.value
          FROM char_vars cv
          JOIN chars c ON c.charid = cv.charid
     LEFT JOIN char_vars opt ON opt.charid = cv.charid AND opt.varname = 'Leaderboard_OptOut'
         WHERE cv.varname = 'Maat_Best_Time'
           AND (cv.expiry = 0 OR cv.expiry > UNIX_TIMESTAMP())
           AND cv.value > 0
           AND (opt.value IS NULL OR opt.value = 0)
      ORDER BY cv.value ASC
         LIMIT %s
        """,
        (_TOP_N,),
    )
    return [(r[0], int(r[1])) for r in cur.fetchall()]


def _query_real_level(cur) -> list[tuple[str, int]]:
    """Top characters by RealLevel CharVar (set by RealLevel_Tracker on login)."""
    cur.execute(
        """
        SELECT c.charname, cv.value
          FROM char_vars cv
          JOIN chars c ON c.charid = cv.charid
     LEFT JOIN char_vars opt ON opt.charid = cv.charid AND opt.varname = 'Leaderboard_OptOut'
         WHERE cv.varname = 'RealLevel'
           AND (cv.expiry = 0 OR cv.expiry > UNIX_TIMESTAMP())
           AND cv.value > 0
           AND (opt.value IS NULL OR opt.value = 0)
      ORDER BY cv.value DESC
         LIMIT %s
        """,
        (_TOP_N,),
    )
    return [(r[0], int(r[1])) for r in cur.fetchall()]


def _query_charvar_top(cur, varname: str) -> list[tuple[str, int]]:
    """Top characters by an arbitrary numeric CharVar (opt-out + expiry aware)."""
    cur.execute(
        """
        SELECT c.charname, cv.value
          FROM char_vars cv
          JOIN chars c ON c.charid = cv.charid
     LEFT JOIN char_vars opt ON opt.charid = cv.charid AND opt.varname = 'Leaderboard_OptOut'
         WHERE cv.varname = %s
           AND (cv.expiry = 0 OR cv.expiry > UNIX_TIMESTAMP())
           AND cv.value > 0
           AND (opt.value IS NULL OR opt.value = 0)
      ORDER BY cv.value DESC
         LIMIT %s
        """,
        (varname, _TOP_N),
    )
    return [(r[0], int(r[1])) for r in cur.fetchall()]


def _query_ws_damage(cur) -> list[tuple[str, int, str]]:
    """Top characters by single weapon skill hit. Returns (charname, damage, ws_name)."""
    cur.execute(
        """
        SELECT c.charname,
               dmg.value AS max_dmg,
               COALESCE(ws.name, CONCAT('WS #', COALESCE(sid.value, '?'))) AS ws_name
          FROM char_vars dmg
          JOIN chars c ON c.charid = dmg.charid
     LEFT JOIN char_vars sid ON sid.charid = dmg.charid AND sid.varname = 'WSMaxDmgSkillId'
     LEFT JOIN weapon_skills ws ON ws.weaponskillid = sid.value
     LEFT JOIN char_vars opt ON opt.charid = dmg.charid AND opt.varname = 'Leaderboard_OptOut'
         WHERE dmg.varname = 'WSMaxDmg'
           AND (dmg.expiry = 0 OR dmg.expiry > UNIX_TIMESTAMP())
           AND dmg.value > 0
           AND (opt.value IS NULL OR opt.value = 0)
      ORDER BY dmg.value DESC
         LIMIT %s
        """,
        (_TOP_N,),
    )
    return [(r[0], int(r[1]), str(r[2])) for r in cur.fetchall()]


def _render_ws_board(heading: str, blurb: str, rows: list[tuple[str, int, str]]) -> str:
    """Four-column board: Rank | Character | Weapon Skill | Damage."""
    lines: list[str] = []
    lines.append(f"### {heading}")
    lines.append("")
    lines.append(f"_{blurb}_")
    lines.append("")
    if not rows:
        lines.append("_No qualifying records yet — be the first!_")
        return "\n".join(lines)
    lines.append("| Rank | Character | Weapon Skill | Damage |")
    lines.append("|---:|---|---|---:|")
    for i, (name, dmg, ws_name) in enumerate(rows, start=1):
        medal = {1: "🥇", 2: "🥈", 3: "🥉"}.get(i, str(i))
        lines.append(f"| {medal} | {_profile_link(name)} | {ws_name} | {dmg:,} |")
    return "\n".join(lines)


def generate(repo_root: Path, docs_dir: Path) -> None:
    conn = connect(repo_root)
    if conn is None:
        print("[leaderboards] skip: no DB connection (LEGENDARY_LIVE_ROOT unset / DB unreachable)")
        return

    page = docs_dir / "community" / "leaderboards.md"
    if not page.exists():
        print(f"[leaderboards] skip: page not found ({page})")
        conn.close()
        return

    cur = conn.cursor()
    boards_written = 0

    try:
        # Freshness banner -- always reflects THIS refresh run (unlike the
        # content-aware page footer from stamp.py, which only bumps when the
        # page body changes). A reliable "is the refresh pipeline alive?"
        # signal even when no stats moved since the last run.
        asof = _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
        if not write_between_markers(page, "lb-asof", f"**\U0001F4CA Leaderboard data as of {asof}**"):
            print("[leaderboards] lb-asof: marker missing in leaderboards.md")

        for board in _SINGLE_VAR_BOARDS:
            rows = _query_single_var(cur, board["var"], board.get("tiebreaker"))
            content = _render_board(
                board["heading"], board["blurb"], board["unit"], rows
            )
            if write_between_markers(page, board["marker"], content):
                boards_written += 1
            else:
                print(f"[leaderboards] {board['marker']}: marker missing in {page.name}")

        # Achievers boards (roll-call style for capstone titles).
        # Different render path because there's no value to sort by —
        # the title is binary, and naming everyone who has it IS the board.
        for board in _ACHIEVERS_BOARDS:
            names = _query_achievers(cur, board["var"])
            content = _render_achievers_board(
                board["heading"], board["blurb"], names
            )
            if write_between_markers(page, board["marker"], content):
                boards_written += 1
            else:
                print(f"[leaderboards] {board['marker']}: marker missing in {page.name}")

        # Combined Reforge boards (current balance + lifetime). Same
        # SQL shape, different var-tuple.
        for combo_board in (_COMBINED_REFORGE_BOARD, _LIFETIME_REFORGE_BOARD):
            rows = _query_summed_vars(cur, combo_board["vars"])
            content = _render_board(
                combo_board["heading"],
                combo_board["blurb"],
                combo_board["unit"],
                rows,
            )
            if write_between_markers(page, combo_board["marker"], content):
                boards_written += 1
            else:
                print(f"[leaderboards] {combo_board['marker']}: marker missing in {page.name}")

        # Pattern-count boards (NM Encyclopedia, etc.) — count of CharVars
        # matching a `LIKE` pattern. Trust Roll Call is also a pattern board
        # but it reads char_spells, not char_vars — handled below.
        for board in _PATTERN_COUNT_BOARDS:
            kind = board.get("kind")
            if kind == "trusts_learned":
                rows = _query_trusts_learned(cur)
            else:
                rows = _query_pattern_count(cur, board["pattern"])
            content = _render_board(
                board["heading"], board["blurb"], board["unit"], rows
            )
            if write_between_markers(page, board["marker"], content):
                boards_written += 1
            else:
                print(f"[leaderboards] {board['marker']}: marker missing in {page.name}")

        # Table-driven boards (chars / char_history / char_jobs).
        _TABLE_DISPATCH = {
            "job_mastery":  _query_job_mastery,
            "playtime":     _query_playtime,
            "deaths":       _query_deaths,
        }
        for board in _TABLE_BOARDS:
            fn = _TABLE_DISPATCH[board["kind"]]
            rows = fn(cur)
            content = _render_board(
                board["heading"], board["blurb"], board["unit"], rows
            )
            if write_between_markers(page, board["marker"], content):
                boards_written += 1
            else:
                print(f"[leaderboards] {board['marker']}: marker missing in {page.name}")

        # Job Rebirth board — SUM of Rebirth_Count_* per character.
        rows = _query_pattern_sum(cur, _JOB_REBIRTH_BOARD["pattern"])
        content = _render_board(
            _JOB_REBIRTH_BOARD["heading"],
            _JOB_REBIRTH_BOARD["blurb"],
            _JOB_REBIRTH_BOARD["unit"],
            rows,
        )
        if write_between_markers(page, _JOB_REBIRTH_BOARD["marker"], content):
            boards_written += 1
        else:
            print(f"[leaderboards] {_JOB_REBIRTH_BOARD['marker']}: marker missing in {page.name}")

        # Speed boards — durations rendered with _format_duration.
        for board in _SPEED_BOARDS:
            if board["kind"] == "speed_from_creation":
                rows = _query_speed_from_creation(cur, board["end_var"])
            elif board["kind"] == "speed_two_var":
                rows = _query_speed_two_var(cur, board["start_var"], board["end_var"])
            else:
                continue
            content = _render_board(
                board["heading"], board["blurb"], "time",
                rows, value_formatter=_format_duration,
            )
            if write_between_markers(page, board["marker"], content):
                boards_written += 1
            else:
                print(f"[leaderboards] {board['marker']}: marker missing in {page.name}")

        # Combat boards
        ws_rows = _query_ws_damage(cur)
        content = _render_ws_board(
            "Hardest Single Weapon Skill Hit",
            "Peak damage dealt by a single weapon skill, recorded server-wide since tracking "
            "began. Your personal best is locked in the moment it fires — only a bigger hit "
            "can replace it.",
            ws_rows,
        )
        if write_between_markers(page, "lb-ws-damage", content):
            boards_written += 1
        else:
            print("[leaderboards] lb-ws-damage: marker missing in leaderboards.md")

        rl_rows = _query_real_level(cur)
        content = _render_board(
            "Highest Real Level",
            "Real Level = job level + gear iLvl bonus + Ascension levels + Job Points + "
            "attribute merits + Rebirths (1 each). Updates on each login via "
            "RealLevel_Tracker. The single number that captures overall character power.",
            "real level",
            rl_rows,
        )
        if write_between_markers(page, "lb-real-level", content):
            boards_written += 1
        else:
            print("[leaderboards] lb-real-level: marker missing in leaderboards.md")

        apex_rows = _query_charvar_top(cur, "Apex_HighestTier")
        content = _render_board(
            "Deepest Apex Trial",
            "Apex Trials is an infinite, scaling solo climb — one Apex boss per tier, harder "
            "forever. This is the highest tier ever cleared: the only number on the server with "
            "no cap. Each new tier banks Paragon Points.",
            "tier",
            apex_rows,
        )
        if write_between_markers(page, "lb-apex-tier", content):
            boards_written += 1
        else:
            print("[leaderboards] lb-apex-tier: marker missing in leaderboards.md")

        paragon_rows = _query_charvar_top(cur, "Paragon_Level")
        content = _render_board(
            "Highest Paragon Level",
            "Paragon Levels are bought with Paragon Points earned in Apex Trials — an infinite "
            "prestige track layered on top of the level cap, unlocking capped perks and the "
            "Daily Might buff along the way.",
            "paragon level",
            paragon_rows,
        )
        if write_between_markers(page, "lb-paragon-level", content):
            boards_written += 1
        else:
            print("[leaderboards] lb-paragon-level: marker missing in leaderboards.md")

        # Maat's Challenge boards
        maat_kill_rows = _query_single_var(cur, "Maat_Kills", None)
        content = _render_board(
            "Most Maat Kills",
            "Total victories against the level-200 Maat in Waughroon Shrine. "
            "Each attempt costs 150 Infamy — the most dedicated challengers rise here.",
            "kills",
            maat_kill_rows,
        )
        if write_between_markers(page, "lb-maat-kills", content):
            boards_written += 1
        else:
            print("[leaderboards] lb-maat-kills: marker missing in leaderboards.md")

        maat_time_rows = _query_maat_best_time(cur)
        content = _render_board(
            "Fastest Maat Kill",
            "Shortest time from Maat's first swing to his defeat in Waughroon Shrine. "
            "Clocked from the moment he engages — pure fighting efficiency at Lv 200.",
            "time",
            maat_time_rows,
            value_formatter=_format_duration,
        )
        if write_between_markers(page, "lb-maat-time", content):
            boards_written += 1
        else:
            print("[leaderboards] lb-maat-time: marker missing in leaderboards.md")

        # Hall of Champions — all Gauntlet clearers (no cap)
        hoc_rows = _query_gauntlet_all(cur)
        content = _render_board(
            "Hall of Champions",
            "Every adventurer who has defeated Shinryu in The Gauntlet, sorted by total clears. "
            "No cutoff — this is the complete roll call. See [The Gauntlet](../endgame/the-gauntlet.md) "
            "for how to earn a spot here.",
            "clears",
            hoc_rows,
        )
        if write_between_markers(page, "lb-hall-of-champions", content):
            boards_written += 1
        else:
            print("[leaderboards] lb-hall-of-champions: marker missing in leaderboards.md")

        # Richest player in gil
        gil_rows = _query_richest_gil(cur)
        content = _render_board(
            "Richest Player (Gil)",
            "Current gil balance from the server's character table. Reflects what's in your "
            "inventory right now — not lifetime earned. The Auction House is a great place to "
            "spend it if you're embarrassed to be on this list.",
            "gil",
            gil_rows,
        )
        if write_between_markers(page, "lb-richest-gil", content):
            boards_written += 1
        else:
            print("[leaderboards] lb-richest-gil: marker missing in leaderboards.md")

        # Tiered combat records — 5 categories × 4 mob-level tiers
        for board in _TIERED_COMBAT_BOARDS:
            cat = board["category"]
            for suffix, tier_label in _TIER_LABELS:
                var     = f"{cat}_{suffix}"
                marker  = f"lb-{cat}-{suffix}"
                heading = f"{board['heading']} — {tier_label}"
                blurb   = board["blurb"].replace("{tier}", tier_label)
                rows    = _query_single_var(cur, var, None)
                content = _render_board(heading, blurb, board["unit"], rows)
                if write_between_markers(page, marker, content):
                    boards_written += 1
                else:
                    print(f"[leaderboards] {marker}: marker missing in {page.name}")

    finally:
        cur.close()
        conn.close()

    print(f"[leaderboards] {boards_written} board(s) written into markers")
