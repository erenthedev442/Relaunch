"""Sync docs/economy/race-changer.md with gil_race_changer.lua.

The Race Changer rewrites your character's race and face for a flat gil fee. Its
config lives inline: a `local config = { ... }` table holds the `cost`, a `races`
list holds the selectable races, and `faceGroups` holds the face options. We pull
the cost from config and count the race / face rows so the published page matches
whatever the menu actually offers.

Markers written:
  race-changer-access  — NPC + zone line
  race-changer-cost    — fee + what you can change (race + face)
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section, commafy


def _parse(text: str) -> dict:
    c: dict = {"name": "Race Changer", "cost": 100000000, "races": 0, "faces": 0}

    config = section(text, "config")

    m = re.search(r"npcName\s*=\s*'([^']+)'", config)
    if m:
        c["name"] = m.group(1)

    m = re.search(r"cost\s*=\s*(\d+)", config)
    if m:
        c["cost"] = int(m.group(1))

    # Count selectable races: each `races` row carries a `label = '...'`.
    races = section(text, "races")
    c["races"] = len(re.findall(r"label\s*=", races))

    # Count faces across every group: each face row carries `face = N`.
    groups = section(text, "faceGroups")
    c["faces"] = len(re.findall(r"face\s*=\s*\d+", groups))

    return c


def _gil_phrase(n: int) -> str:
    """100000000 -> '100M gil (100,000,000)'."""
    if n >= 1_000_000 and n % 1_000_000 == 0:
        return f"{n // 1_000_000}M gil ({commafy(n)} gil)"
    return f"{commafy(n)} gil"


# ---------------------------------------------------------------------------

def _render_access(c: dict) -> str:
    return (
        f"The **{c['name']}** stands in the services row of "
        f"**{{{{npc:race_changer}}}}** (`!hub`). Talk to it, choose a new race and face, then confirm."
    )


def _render_cost(c: dict) -> str:
    races = c["races"]
    faces = c["faces"]
    return (
        f"A race change costs **{_gil_phrase(c['cost'])}**, charged once when you "
        f"confirm. You can switch to any of the **{races} races** "
        f"(your current one is left off the list) and pick from **{faces} faces** "
        f"per race. The change is instant and purely cosmetic — your size, level, "
        f"jobs, and everything else stay exactly as they were."
    )


# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/gil_race_changer.lua")
    if src is None:
        print("[race_changer] skip: gil_race_changer.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    c = _parse(text)

    page = docs_dir / "economy" / "race-changer.md"
    blocks = [
        ("race-changer-access", _render_access(c)),
        ("race-changer-cost", _render_cost(c)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[race_changer] {written}/{len(blocks)} marker block(s) written "
          f"(cost={c['cost']}, races={c['races']}, faces={c['faces']})")
