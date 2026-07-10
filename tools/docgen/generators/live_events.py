"""Sync the Live Events page + its call-outs from the three live event sources.

Three standing, clock-driven bonuses ship with the relaunch (2026-07-10):

  Happy Hour             modules/custom/lua/happy_hour.lua — daily UTC window(s)
                         during which everyone online gets +EXP% (Dedication) and
                         +CP% (Commitment) automatically.
  City of the Day        scripts/globals/dynamis_divergence.lua — one [D] city is
                         featured per UTC day (featuredZoneToday()); a full clear
                         pays every member the CITY_BONUS medals on top of spoils.
  Weekly featured NM     modules/custom/lua/unity_wanted.lua — one Unity Wanted NM
                         per epoch week (weeklyFeaturedId()) pays a doubled kill
                         reward; roster size comes from unity_wanted_catalog.lua.

One parse renders BOTH the Live Events page and the shorter call-outs on the
system detail pages, so the three surfaces can't drift apart:

  docs/endgame/live-events.md          markers live-events-happy-hour /
                                       live-events-city / live-events-unity
  docs/endgame/dynamis-divergence.md   marker divergence-city-of-day
  docs/endgame/unity-concord.md        marker unity-weekly-featured

City display names are read from the live Divergence portal labels (reusing
dynamis_divergence._parse_portals), keyed by the rotation's zone ids. All
parses fail closed: if a source or field is missing the affected marker keeps
its previously-published content rather than publishing holes.

The schedules are deterministic (epoch-day / epoch-week arithmetic), which is
what lets the player portal's Live Events board (portal.ffxi-legendary.com/
events.html) mirror them with countdowns — the pages link there for "what's on
right now" instead of baking a build-time snapshot that could go stale.

Player-facing language only: no .lua names, effect ids, or charVar jargon.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._lua import table_body, entry_blocks, field_num
from tools.docgen.generators.dynamis_divergence import _parse_portals

_PORTAL_URL = "https://portal.ffxi-legendary.com/events.html"

# Friendly names for the City-of-the-Day bonus items (same pattern as the
# dynamis_divergence generator's _MATERIAL_NAMES: item_basic carries the
# apostrophe-less internal names).
_MEDAL_NAMES = {
    9541: "Kindred's Medal",
    9542: "Kindred Crest",   # unused today; keeps a retune readable
    9543: "Demon's Medal",
}


# ---------------------------------------------------------------------------
# Parsing
# ---------------------------------------------------------------------------

def _parse_happy_hour(text: str) -> dict | None:
    """WINDOWS + the two bonus percentages from happy_hour.lua."""
    body = table_body(text, "WINDOWS")
    if body is None:
        return None
    windows = []
    for inner in entry_blocks(body):
        hour = field_num(inner, "hour")
        minute = field_num(inner, "min")
        dur = field_num(inner, "durationMin")
        if hour is None or minute is None or dur is None:
            continue
        windows.append((int(hour), int(minute), int(dur)))
    exp = field_num(text, "EXP_BONUS")
    cp = field_num(text, "CP_BONUS")
    if not windows or exp is None or cp is None:
        return None
    return {"windows": windows, "exp": int(exp), "cp": int(cp)}


def _parse_city_of_day(engine_text: str, portals_text: str) -> dict | None:
    """Rotation (featuredZoneToday) + CITY_BONUS medals + live city labels."""
    m = re.search(
        r"featuredZoneToday\s*=\s*function\s*\(\s*\)\s*"
        r"return\s*(\d+)\s*\+\s*\(\s*math\.floor\s*\(\s*os\.time\s*\(\s*\)\s*/\s*86400\s*\)\s*%\s*(\d+)\s*\)",
        engine_text,
    )
    if not m:
        return None
    base, count = int(m.group(1)), int(m.group(2))

    bonus_body = table_body(engine_text, "CITY_BONUS")
    if bonus_body is None:
        return None
    bonus = []
    for inner in entry_blocks(bonus_body):
        item_id = field_num(inner, "id")
        qty = field_num(inner, "qty")
        if item_id is None or qty is None:
            continue
        name = _MEDAL_NAMES.get(int(item_id), f"item #{int(item_id)}")
        bonus.append((int(qty), name))
    if not bonus:
        return None

    zone_labels = _parse_portals(portals_text).get("zone_labels", {})
    cities = [zone_labels.get(z) for z in range(base, base + count)]
    if not all(cities):
        return None
    return {"cities": cities, "count": count, "bonus": bonus}


def _parse_unity_weekly(wanted_text: str, catalog_text: str) -> dict | None:
    """Weekly cadence + reward multiplier + roster size."""
    m = re.search(
        r"weeklyFeaturedId\s*\(\s*\)\s*"
        r"return\s*\(\s*math\.floor\s*\(\s*os\.time\s*\(\s*\)\s*/\s*604800\s*\)\s*%\s*#catalog\.nms\s*\)\s*\+\s*1",
        wanted_text,
    )
    if not m:
        return None
    mult_m = re.search(r"reward\s*=\s*reward\s*\*\s*(\d+)", wanted_text)
    if not mult_m:
        return None

    nms_body = table_body(catalog_text, "nms")
    if nms_body is None:
        return None
    roster = sum(1 for inner in entry_blocks(nms_body)
                 if field_num(inner, "id") is not None)
    if roster == 0:
        return None
    return {"mult": int(mult_m.group(1)), "roster": roster}


# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------

def _fmt_window(hour: int, minute: int, dur: int) -> str:
    end = hour * 60 + minute + dur
    return (f"**{hour:02d}:{minute:02d}–"
            f"{(end // 60) % 24:02d}:{end % 60:02d} UTC**")


def _render_happy_hour(c: dict) -> str:
    windows = " and ".join(_fmt_window(*w) for w in c["windows"])
    return "\n".join([
        f"Happy Hour runs **daily**, {windows}. Everyone online gets "
        f"**+{c['exp']}% EXP** and **+{c['cp']}% Capacity Points** for the rest "
        "of the window — applied automatically within a minute (your chat log "
        "announces it), including when you log in or zone in mid-window.",
        "",
        "- Nothing to sign up for and nowhere to be — it works in every zone, "
        "on every job and level.",
        "- A stronger EXP/CP buff you already have (say, from a ring) is never "
        "downgraded — Happy Hour only applies where it's the better deal.",
    ])


def _render_city(c: dict, on_divergence_page: bool) -> str:
    medals = " and ".join(f"**{qty}× {name}**" for qty, name in c["bonus"])
    rotation = " → ".join(f"**{label}**" for label in c["cities"])
    divergence = ("[D]" if on_divergence_page
                  else "[Dynamis — Divergence](dynamis-divergence.md)")
    lines = [
        f"One of the four {divergence} cities is **featured each day**: finish "
        f"the featured city's run and **every member of the clear** is paid "
        f"{medals} on top of the normal spoils.",
        "",
        f"The rotation is fixed — it flips at **00:00 UTC** and repeats every "
        f"{c['count']} days:",
        "",
        rotation,
        "",
        f"Today's featured city, with a countdown to the next flip, is on the "
        f"[Live Events board]({_PORTAL_URL})"
        + (" and the [Live Events](live-events.md) page."
           if on_divergence_page else "."),
    ]
    return "\n".join(lines)


def _render_unity(c: dict, on_unity_page: bool) -> str:
    board = ("the board" if on_unity_page
             else "the [Unity Concord](unity-concord.md) board")
    reward = ("**double accolades**" if c["mult"] == 2
              else f"**{c['mult']}× accolades**")
    return "\n".join([
        f"One of the **{c['roster']} Wanted NMs** on {board} is **featured "
        f"each week**, and its kill pays {reward} (the spawn cost doesn't "
        "change). The featured hunt is pinned to the top of the board menu as "
        "**Weekly:** and starred (`*`) in the tier lists.",
        "",
        f"The feature moves to the next NM on the roster every **Thursday at "
        f"00:00 UTC**. This week's NM, with a countdown, is on the "
        f"[Live Events board]({_PORTAL_URL})"
        + (" and the [Live Events](live-events.md) page."
           if on_unity_page else "."),
    ])


# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    hh_src = resolve_source(repo_root, "modules/custom/lua/happy_hour.lua")
    engine_src = resolve_source(repo_root, "scripts/globals/dynamis_divergence.lua")
    portals_src = resolve_source(repo_root, "modules/custom/lua/Dynamis_Divergence.lua")
    wanted_src = resolve_source(repo_root, "modules/custom/lua/unity_wanted.lua")
    catalog_src = resolve_source(repo_root, "modules/custom/lua/unity_wanted_catalog.lua")

    hh = (_parse_happy_hour(hh_src.read_text(encoding="utf-8", errors="replace"))
          if hh_src else None)
    city = (_parse_city_of_day(
                engine_src.read_text(encoding="utf-8", errors="replace"),
                portals_src.read_text(encoding="utf-8", errors="replace"))
            if engine_src and portals_src else None)
    unity = (_parse_unity_weekly(
                wanted_src.read_text(encoding="utf-8", errors="replace"),
                catalog_src.read_text(encoding="utf-8", errors="replace"))
             if wanted_src and catalog_src else None)

    events_page = docs_dir / "endgame" / "live-events.md"
    blocks: list[tuple[Path, str, str | None]] = [
        (events_page, "live-events-happy-hour",
         _render_happy_hour(hh) if hh else None),
        (events_page, "live-events-city",
         _render_city(city, on_divergence_page=False) if city else None),
        (events_page, "live-events-unity",
         _render_unity(unity, on_unity_page=False) if unity else None),
        (docs_dir / "endgame" / "dynamis-divergence.md", "divergence-city-of-day",
         _render_city(city, on_divergence_page=True) if city else None),
        (docs_dir / "endgame" / "unity-concord.md", "unity-weekly-featured",
         _render_unity(unity, on_unity_page=True) if unity else None),
    ]

    written = 0
    for page, marker, content in blocks:
        if content is None:
            print(f"[live_events] skip {marker}: source missing/unparsed — "
                  "keeping previous content")
            continue
        if write_between_markers(page, marker, content):
            written += 1
        else:
            print(f"[live_events] marker {marker} not found on {page.name}")

    print(f"[live_events] {written}/{len(blocks)} marker block(s) written "
          f"(happy_hour={'ok' if hh else 'skip'}, "
          f"city={'ok' if city else 'skip'}, "
          f"unity={'ok' if unity else 'skip'})")
