"""Generate docs/community/highlights.md — the Hall of Fame — from the live
world-first records in the database.

FULL-PAGE writer (idiom: spells.py). Two recording systems feed it:

  modules/custom/lua/world_first_announcements.lua
      Server-wide firsts. On each first it writes TWO ServerVars:
        WF_<KEY> = charid of the record holder
        WT_<KEY> = unix timestamp of the moment
      Keys: PLAYER_DEATH, PLAYER_LEVEL_UP/DOWN, JOB_<lvl>_<JOB> (level
      milestones per job), NM_KILL_<MOBNAME> (first kill of every NM).

  modules/custom/lua/achievements.lua
      Personal milestones. award() stamps CharVar 'ACH_<id>' = os.time(),
      so the EARLIEST holder of an ACH_* var is the server-first achiever,
      with a date. (ids: APEX_HUNTER = first Tier V HL kill,
      FIRST_ASCENSION, RAID_FIRST_KILL, ...)

DB access mirrors tools/docgen/generators/leaderboards.py via
tools/docgen/_db.connect(): if the DB is unreachable (CI / local build
without LEGENDARY_LIVE_ROOT) the module SKIPS WITHOUT WRITING, so the last
box-generated page survives. GM characters are excluded with the
`chars.gmlevel = 0` filter economy.py uses, plus leaderboards.py's
`Leaderboard_OptOut` CharVar opt-out.

The milestone LIST is a module constant (seeded from the hand-written page's
rows); rows whose milestone has no queryable record render with em-dashes.
Firsts are only claimed when the data shows them: rows backed by a
timestamped record fill in (player, date); flag-only milestones (no
timestamp, so "who was first" is unknowable) stay as placeholders. The
Records table rows have no queryable source yet and stay constant.

No last-updated footer — stamp.py owns that.
"""
from __future__ import annotations

import datetime as _dt
import re
from pathlib import Path

from tools.docgen._db import connect
from tools.docgen._paths import resolve_source
from tools.docgen.generators.leaderboards import _profile_link

_TAG = "[highlights_page]"

_DASH = "—"

# Values below this can't be unix timestamps (guards against any legacy
# flag-style `= 1` values sneaking into a MIN() ordering).
_TS_FLOOR = 1_000_000_000


# ---------------------------------------------------------------------------
# The aspirational milestone list. Constant (seeded from the hand-written
# page) — only the (player, date, notes) cells are data-driven.
#
# resolver kinds:
#   ach     — earliest 'ACH_<id>' CharVar (achievements.lua stamps os.time())
#   wf      — a single WF_<key>/WT_<key> ServerVar pair
#   wf_like — earliest WT among ServerVars matching a WF_ LIKE pattern;
#             `notes_from` derives the Notes cell from the winning var name
#   None    — nothing records this yet; renders as em-dashes
# ---------------------------------------------------------------------------
_SERVER_FIRSTS: list[dict] = [
    {
        "label":    "First Rank V (Legend) in Hunting League",
        "resolver": {"kind": "ach", "id": "APEX_HUNTER"},
        "notes":    "First Tier V NM kill — the *Apex Hunter* achievement",
    },
    {
        "label":    "First Reforge +3 piece",
        "resolver": None,   # Reforge_System.lua records no first-+3 stamp yet
        "notes":    "",
    },
    {
        "label":    "First Wave Master Insane clear",
        "resolver": None,   # GM_Wave_Clears is an undated bitfield — order unknowable
        "notes":    "",
    },
    {
        "label":    "First Weekly Hunt Board sweep (all 5 completed)",
        "resolver": None,   # WH_AllCleared_Lifetime is an undated counter
        "notes":    "",
    },
    {
        "label":    "First Hunter's Guild Trinity status",
        "resolver": None,   # Title_Trinity_Hunter is an undated 0/1 flag
        "notes":    "Grandmaster in all 3 Reforge guilds (AF / Relic / Empy)",
    },
    {
        "label":    "First adventurer to reach level 99",
        "resolver": {"kind": "wf_like", "pattern": r"WF\_JOB\_99\_%", "notes_from": "job"},
        "notes":    "",
    },
    {
        "label":    "First NM slain in Vana'diel",
        "resolver": {"kind": "wf_like", "pattern": r"WF\_NM\_KILL\_%", "notes_from": "nm"},
        "notes":    "",
    },
    {
        "label":    "First player to fall in battle",
        "resolver": {"kind": "wf", "key": "PLAYER_DEATH"},
        "notes":    "The server's first KO — wear it proudly",
    },
    {
        "label":    "First Prestige Ascension",
        "resolver": {"kind": "ach", "id": "FIRST_ASCENSION"},
        "notes":    "The *First Ascension* achievement",
    },
    {
        "label":    "First Star-Devourer raid kill",
        "resolver": {"kind": "ach", "id": "RAID_FIRST_KILL"},
        "notes":    "The *Star-Slayer* achievement",
    },
]

# Records rows: no queryable single-source-of-truth yet — constant
# placeholders (the live, queryable records live on the Leaderboards page).
_RECORDS: list[tuple[str, str, str, str]] = [
    ("Most Hunt Marks earned in a week",     _DASH, _DASH, _DASH),
    ("Most Infamy earned in a single run",   _DASH, _DASH, _DASH),
    ("Highest augmented item score",         _DASH, _DASH, _DASH),
    ("Most NMs killed in a single day",      _DASH, _DASH, _DASH),
]


# ---------------------------------------------------------------- queries


def _q_ach_first(cur, ach_id: str) -> tuple[str, int] | None:
    """Earliest holder of CharVar ACH_<id> (value = award unix time)."""
    cur.execute(
        """
        SELECT c.charname, cv.value
          FROM char_vars cv
          JOIN chars c ON c.charid = cv.charid AND c.gmlevel = 0
     LEFT JOIN char_vars opt ON opt.charid = cv.charid
                            AND opt.varname = 'Leaderboard_OptOut'
         WHERE cv.varname = %s
           AND cv.value > %s
           AND (cv.expiry = 0 OR cv.expiry > UNIX_TIMESTAMP())
           AND (opt.value IS NULL OR opt.value = 0)
      ORDER BY cv.value ASC
         LIMIT 1
        """,
        (f"ACH_{ach_id}", _TS_FLOOR),
    )
    row = cur.fetchone()
    return (row[0], int(row[1])) if row else None


def _q_wf(cur, key: str) -> tuple[str, int | None] | None:
    """The WF_<key> holder + WT_<key> timestamp (timestamp may be absent)."""
    cur.execute(
        """
        SELECT c.charname, wt.value
          FROM server_variables wf
          JOIN chars c ON c.charid = wf.value AND c.gmlevel = 0
     LEFT JOIN server_variables wt ON wt.name = %s
     LEFT JOIN char_vars opt ON opt.charid = c.charid
                            AND opt.varname = 'Leaderboard_OptOut'
         WHERE wf.name = %s
           AND (wf.expiry = 0 OR wf.expiry > UNIX_TIMESTAMP())
           AND (opt.value IS NULL OR opt.value = 0)
         LIMIT 1
        """,
        (f"WT_{key}", f"WF_{key}"),
    )
    row = cur.fetchone()
    if not row:
        return None
    ts = int(row[1]) if row[1] is not None else None
    return (row[0], ts)


def _q_wf_like(cur, pattern: str) -> tuple[str, str, int | None] | None:
    """Earliest record among WF_ vars matching a LIKE pattern.
    Returns (wf_var_name, charname, timestamp|None)."""
    cur.execute(
        """
        SELECT wf.name, c.charname, wt.value
          FROM server_variables wf
          JOIN chars c ON c.charid = wf.value AND c.gmlevel = 0
     LEFT JOIN server_variables wt ON wt.name = CONCAT('WT_', SUBSTRING(wf.name, 4))
     LEFT JOIN char_vars opt ON opt.charid = c.charid
                            AND opt.varname = 'Leaderboard_OptOut'
         WHERE wf.name LIKE %s
           AND (wf.expiry = 0 OR wf.expiry > UNIX_TIMESTAMP())
           AND (opt.value IS NULL OR opt.value = 0)
      ORDER BY COALESCE(wt.value, 2147483647) ASC
         LIMIT 1
        """,
        (pattern,),
    )
    row = cur.fetchone()
    if not row:
        return None
    ts = int(row[2]) if row[2] is not None else None
    return (row[0], row[1], ts)


# ---------------------------------------------------------------- helpers


def _job_names(repo_root: Path) -> dict[str, str]:
    """'WAR' -> 'Warrior' from scripts/enum/job_name.lua (the table the
    world-first recorder itself uses to build var names)."""
    src = resolve_source(repo_root, "scripts/enum/job_name.lua")
    if src is None:
        return {}
    text = src.read_text(encoding="utf-8", errors="replace")
    return {
        abbr: full
        for abbr, full in re.findall(r"\{\s*'(\w+)'\s*,\s*'([^']+)'\s*\}", text)
    }


def _date(ts: int | None) -> str:
    if ts is None or ts < _TS_FLOOR:
        return _DASH
    return _dt.datetime.fromtimestamp(ts, _dt.timezone.utc).strftime("%Y-%m-%d")


def _pretty_nm(var_name: str) -> str:
    # 'WF_NM_KILL_LEAPING_LIZZY' -> 'Leaping Lizzy'
    raw = var_name[len("WF_NM_KILL_"):]
    return " ".join(w.capitalize() for w in raw.split("_"))


def _resolve_rows(cur, repo_root: Path) -> tuple[list[tuple[str, str, str, str]], int]:
    jobs = _job_names(repo_root)
    rows: list[tuple[str, str, str, str]] = []
    filled = 0

    for ms in _SERVER_FIRSTS:
        label, notes = ms["label"], ms["notes"]
        player = date = _DASH
        spec = ms["resolver"]

        if spec is not None:
            kind = spec["kind"]
            if kind == "ach":
                hit = _q_ach_first(cur, spec["id"])
                if hit:
                    player, date = _profile_link(hit[0]), _date(hit[1])
            elif kind == "wf":
                hit = _q_wf(cur, spec["key"])
                if hit:
                    player, date = _profile_link(hit[0]), _date(hit[1])
            elif kind == "wf_like":
                hit = _q_wf_like(cur, spec["pattern"])
                if hit:
                    var_name, charname, ts = hit
                    player, date = _profile_link(charname), _date(ts)
                    if spec.get("notes_from") == "job":
                        abbr = var_name.rsplit("_", 1)[-1]
                        full = jobs.get(abbr)
                        notes = f"{full} ({abbr})" if full else abbr
                    elif spec.get("notes_from") == "nm":
                        notes = _pretty_nm(var_name)

        if player != _DASH:
            filled += 1
        rows.append((label, player, date, notes))

    return rows, filled


# ---------------------------------------------------------------- render


def _render(first_rows: list[tuple[str, str, str, str]]) -> str:
    L: list[str] = []
    A = L.append

    A("# Hall of Fame")
    A("")
    A(
        "This page celebrates the server's biggest moments — server firsts, "
        "record clears, and community milestones. As the server grows, so does "
        "this list."
    )
    A("")
    A('!!! info "This page grows with the community."')
    A(
        "    We're still early. The rows below fill in automatically as the "
        "world-first trackers fire — and staff add the rest from Discord "
        "submissions. Check back often, and if you hit a milestone, post it so "
        "we can celebrate it here."
    )
    A("")
    A("---")
    A("")
    A("## Server Firsts")
    A("")
    A(
        "Rows marked with a player name are pulled live from the server's "
        "world-first records (the in-game announcement trackers). Rows still "
        "showing dashes are waiting on their first — or on a tracker."
    )
    A("")
    A("| Achievement | Player | Date | Notes |")
    A("|---|---|---|---|")
    for label, player, date, notes in first_rows:
        A(f"| {label} | {player} | {date} | {notes} |")
    A("")
    A("---")
    A("")
    A("## Records")
    A("")
    A("| Category | Record | Player | Date |")
    A("|---|---|---|---|")
    for cat, record, player, date in _RECORDS:
        A(f"| {cat} | {record} | {player} | {date} |")
    A("")
    A(
        "_Looking for live, always-current records? The "
        "[Leaderboards](leaderboards.md) page tracks combat records, speed "
        "runs, and every grind metric straight from the database._"
    )
    A("")
    A("---")
    A("")
    A("## Submit a Highlight")
    A("")
    A(
        "Hit a server first? Set a record? Do something embarrassingly "
        "impressive? Post it in **#general** on Discord with a screenshot. "
        "Staff review submissions weekly and update this page. We want to "
        "celebrate the people who are pushing the server forward."
    )
    A("")
    A(
        "Community milestones — total kills, total marks earned, total Infamy "
        "banked — will be added here as the server matures. This is your "
        "history."
    )
    A("")

    return "\n".join(L)


# ---------------------------------------------------------------- entry point


def generate(repo_root: Path, docs_dir: Path) -> None:
    conn = connect(repo_root)
    if conn is None:
        # Mirrors leaderboards.py: no DB (CI / local) -> keep the last good
        # published page rather than clobbering it with empty dashes.
        print(f"{_TAG} skip: no DB connection (LEGENDARY_LIVE_ROOT unset / DB unreachable)")
        return

    try:
        cur = conn.cursor()
        try:
            rows, filled = _resolve_rows(cur, repo_root)
        finally:
            cur.close()
    except Exception as e:
        # Any query failure (missing table, schema drift): fail closed.
        print(f"{_TAG} skip: DB query failed ({e}); keeping existing page")
        conn.close()
        return
    conn.close()

    content = _render(rows)
    page = docs_dir / "community" / "highlights.md"
    page.parent.mkdir(parents=True, exist_ok=True)
    page.write_text(content, encoding="utf-8")
    print(
        f"{_TAG} wrote community/highlights.md "
        f"({filled}/{len(rows)} server-firsts filled from live data, "
        f"{len(_RECORDS)} record rows constant)"
    )
