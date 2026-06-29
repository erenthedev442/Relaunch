"""Sync docs/endgame/dungeons.md with dungeon_catalog.lua.

Everything player-facing derives from the live catalog so the page tracks
tuning changes automatically:
  * catalog.npc           -> entry NPC zone (updates if the NPC moves)
  * catalog.categories    -> category labels + dungeon ordering
  * catalog.dungeons      -> per-dungeon label, level, mob names, boss
  * catalog.completionDelay -> exit countdown in seconds

Markers written:
  dungeon-overview  -- entry instructions, NPC zone, timer, party rules
  dungeon-list      -- per-category tables (dungeon, level, trash mobs, boss)
  dungeon-tips      -- practical tips (coord broadcast, countdown, recovery)
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section


_FRIENDLY_ZONE: dict[str, str] = {
    "GM_Home":                   "GM Home",
    "Leafallia":                 "Leafallia",
    "Celennia_Memorial_Library": "the Celennia Memorial Library",
}

# One-liner shown beneath each category heading on the page.
_CAT_INTRO: dict[str, str] = {
    "Challenge Dungeons":
        "Harder than progression content — a real test of your build.",
    "Progression Dungeons":
        "Mid-game runs with solid EXP and consistent drops for players still climbing the gear curve.",
    "Augmentation Dungeons":
        "Farm-friendly runs with strong augment-material drop rates.",
}


# ---------------------------------------------------------------------------
# Parsing helpers

def _str_val(block: str, field: str) -> str:
    """Read a double- or single-quoted string field from a Lua block."""
    m = re.search(rf'{re.escape(field)}\s*=\s*"([^"]*)"', block)
    if not m:
        m = re.search(rf"{re.escape(field)}\s*=\s*'([^']*)'", block)
    return m.group(1) if m else ""


def _int_val(block: str, field: str) -> int:
    m = re.search(rf"{re.escape(field)}\s*=\s*(\d+)", block)
    return int(m.group(1)) if m else 0


def _roster_names(block: str):
    """Return (firstName, secondName, bossName) from a dungeon's buildRoster call.

    The route-array closing `},` is the only one in the block followed by a quoted
    string — individual position entries' `},` are always followed by `{` or `}`.
    Names containing apostrophes (e.g. "Fei'Yin Golem") use double quotes in the
    catalog; all others use single quotes. The pattern handles both.
    """
    m = re.search(
        r"""\},\s*(?:"([^"]*)"|'([^']*)')\s*,\s*(?:"([^"]*)"|'([^']*)')\s*,\s*(?:"([^"]*)"|'([^']*)')\s*,\s*\d+""",
        block,
    )
    if not m:
        return "?", "?", "?"
    return (
        m.group(1) if m.group(1) is not None else m.group(2),
        m.group(3) if m.group(3) is not None else m.group(4),
        m.group(5) if m.group(5) is not None else m.group(6),
    )


def _parse(text: str) -> dict:
    # NPC entry zone — read from catalog.npc.zone
    npc_block = section(text, "catalog.npc")
    zone_raw = re.search(r"zone\s*=\s*'([^']+)'", npc_block)
    raw = zone_raw.group(1) if zone_raw else "GM_Home"
    npc_zone = _FRIENDLY_ZONE.get(raw, raw.replace("_", " "))

    completion_delay = _int_val(text, "catalog.completionDelay")

    # Categories — preserve catalog ordering so the page matches the in-game menu
    cats_block = section(text, "catalog.categories")
    categories: list[dict] = []
    for m in re.finditer(
        r"label\s*=\s*'([^']+)'.*?dungeonKeys\s*=\s*\{([^}]*)\}",
        cats_block, re.DOTALL,
    ):
        keys = re.findall(r"'([^']+)'", m.group(2))
        categories.append({"label": m.group(1), "dungeonKeys": keys})

    # Dungeons — parse each key's sub-block inside catalog.dungeons
    dungs_block = section(text, "catalog.dungeons")
    all_keys = [k for cat in categories for k in cat["dungeonKeys"]]
    dungeons: dict[str, dict] = {}
    for key in all_keys:
        block = section(dungs_block, key)
        if not block:
            continue
        first, second, boss = _roster_names(block)
        dungeons[key] = {
            "label":      _str_val(block, "label"),
            "level":      _int_val(block, "level"),
            "firstName":  first,
            "secondName": second,
            "bossName":   boss,
        }

    return {
        "npc_zone":         npc_zone,
        "completion_delay": completion_delay,
        "categories":       categories,
        "dungeons":         dungeons,
        "n_total":          sum(len(c["dungeonKeys"]) for c in categories),
    }


# ---------------------------------------------------------------------------
# Renderers

def _render_overview(c: dict) -> str:
    delay = c["completion_delay"]
    return (
        f"Talk to the **Dungeon Guide** in **{c['npc_zone']}** to register. "
        "Choose a category, then a dungeon, and confirm — you must be the party leader "
        "and every member of your group must be in the same zone when you register "
        "(no one in transit, no one already in an active dungeon).\n\n"
        f"Each run gives your party **30 minutes** to defeat all **13 mobs**, including "
        f"a final boss. When the last enemy falls a **{delay}-second exit countdown** "
        "begins — use the time to collect drops, then you're automatically warped back."
    )


def _render_list(c: dict) -> str:
    lines: list[str] = []
    for cat in c["categories"]:
        intro = _CAT_INTRO.get(cat["label"], "")
        lines.append(f"### {cat['label']}")
        if intro:
            lines.extend(["", intro])
        lines.extend([
            "",
            "| Dungeon | Recommended level | Trash × 12 | Boss |",
            "|---|---|---|---|",
        ])
        for key in cat["dungeonKeys"]:
            d = c["dungeons"].get(key)
            if not d:
                continue
            trash = f"{d['firstName']}, {d['secondName']} (×6 each)"
            lines.append(f"| **{d['label']}** | {d['level']} | {trash} | {d['bossName']} |")
        lines.append("")
    return "\n".join(lines).rstrip()


def _render_tips(c: dict) -> str:
    delay = c["completion_delay"]
    return (
        "**Finding stragglers** — when 3 or fewer mobs remain, the server prints "
        "their map coordinates to your party chat so you can track them down without "
        "sweeping the whole zone.\n\n"
        f"**Exit window** — you have **{delay} seconds** after the last kill before "
        "the warp fires automatically. There's no manual exit command; just wait.\n\n"
        "**Got stuck?** If you crashed mid-run and can't re-enter the zone on login, "
        "use `!closedungeon` to force-close your session and return to GM Home. "
        "A GM can also run `!closedungeon YourName` to clear a stuck session remotely."
    )


# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/dungeon_catalog.lua")
    if src is None:
        print("[dungeon_instances] skip: dungeon_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    c = _parse(text)

    page = docs_dir / "endgame" / "dungeons.md"
    blocks = [
        ("dungeon-overview", _render_overview(c)),
        ("dungeon-list",     _render_list(c)),
        ("dungeon-tips",     _render_tips(c)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[dungeon_instances] {written}/{len(blocks)} marker block(s) written "
          f"({c['n_total']} dungeons across {len(c['categories'])} categories)")
