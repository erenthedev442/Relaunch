"""Parse a pasted `!mystats` dump into a baseline ("anchor") of FINAL stats.

`!mystats` (modules/custom/commands/mystats.lua) prints the player's stats with
equipment + buffs + job traits + merits + JP gifts ALREADY summed by the engine.
That makes it the ground truth the engine can't cheaply reconstruct from the DB
(traits/merits/JP don't live in char_equip). The anchored-delta model pins the
equipped set to these numbers, then applies DB-sourced gear *deltas* for swaps.

CAPTURE THE ANCHOR UNBUFFED AND WITHOUT FOOD, in the same gear that is currently
equipped in the DB. Buffs/food break the linear ATT/ACC decomposition the engine
relies on (settings notes in tools/dpscalc/state.py).
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path


@dataclass
class Anchor:
    main_job: str = "?"
    main_lvl: int = 0
    sub_job: str = "?"
    sub_lvl: int = 0
    stats: dict[str, int] = field(default_factory=dict)  # STR..CHR (final)
    att: int = 0
    acc: int = 0
    wpn_dmg: int = 0
    ratt: int = 0
    racc: int = 0
    rwpn_dmg: int = 0
    crit_rate: int = 0
    crit_dmg: int = 0
    da: int = 0
    ta: int = 0
    qa: int = 0
    defense: int = 0
    evasion: int = 0
    haste_gear: int = 0
    haste_magic: int = 0
    haste_ability: int = 0
    dual_wield: int = 0
    store_tp: int = 0
    tp_bonus: int = 0
    ws_dmg_all: int = 0
    ws_dmg_first: int = 0


_RX = {
    "job": re.compile(r"Job:\s*([A-Za-z]+)\s*(\d+)\s*/\s*([A-Za-z]+)\s*(\d+)"),
    "attr1": re.compile(r"STR\s*(\d+)\s*DEX\s*(\d+)\s*VIT\s*(\d+)\s*AGI\s*(\d+)"),
    "attr2": re.compile(r"INT\s*(\d+)\s*MND\s*(\d+)\s*CHR\s*(\d+)"),
    "melee": re.compile(r"Melee\s*ATT\s*(\d+)\s*ACC\s*(\d+)\s*Wpn dmg\s*(\d+)"),
    "ranged": re.compile(r"Ranged\s*ATT\s*(\d+)\s*ACC\s*(\d+)\s*Wpn dmg\s*(\d+)"),
    "crit": re.compile(r"Crit hit rate\s*(\d+)%\s*Crit dmg\s*\+?(\d+)%"),
    "multi": re.compile(r"Dbl Atk\s*(\d+)%\s*Trpl Atk\s*(\d+)%\s*Quad Atk\s*(\d+)%"),
    "def": re.compile(r"DEF\s*(\d+)\s*EVA\s*(\d+)"),
    # Haste values print as "current/cap"; capture the current side only.
    "haste": re.compile(
        r"Haste-Gear\s*(-?\d+)(?:/\d+)?\s*Haste-Magic\s*(-?\d+)(?:/\d+)?"
        r"\s*Haste-Ability\s*(-?\d+)(?:/\d+)?"
    ),
    "tempo": re.compile(r"Dual Wield\s*(\d+)%\s*Store TP\s*(-?\d+)\s*TP Bonus\s*\+?(-?\d+)"),
    "wsdmg": re.compile(
        r"WS dmg \(all hits\)\s*\+?(-?\d+)%\s*WS dmg \(1st hit\)\s*\+?(-?\d+)%"
    ),
}


def parse_anchor_text(text: str) -> Anchor:
    a = Anchor()

    m = _RX["job"].search(text)
    if m:
        a.main_job, a.main_lvl = m.group(1).upper(), int(m.group(2))
        a.sub_job, a.sub_lvl = m.group(3).upper(), int(m.group(4))

    m = _RX["attr1"].search(text)
    if m:
        a.stats["STR"], a.stats["DEX"] = int(m.group(1)), int(m.group(2))
        a.stats["VIT"], a.stats["AGI"] = int(m.group(3)), int(m.group(4))
    m = _RX["attr2"].search(text)
    if m:
        a.stats["INT"], a.stats["MND"], a.stats["CHR"] = (
            int(m.group(1)), int(m.group(2)), int(m.group(3)))

    m = _RX["melee"].search(text)
    if m:
        a.att, a.acc, a.wpn_dmg = int(m.group(1)), int(m.group(2)), int(m.group(3))
    m = _RX["ranged"].search(text)
    if m:
        a.ratt, a.racc, a.rwpn_dmg = int(m.group(1)), int(m.group(2)), int(m.group(3))

    m = _RX["crit"].search(text)
    if m:
        a.crit_rate, a.crit_dmg = int(m.group(1)), int(m.group(2))
    m = _RX["multi"].search(text)
    if m:
        a.da, a.ta, a.qa = int(m.group(1)), int(m.group(2)), int(m.group(3))

    m = _RX["def"].search(text)
    if m:
        a.defense, a.evasion = int(m.group(1)), int(m.group(2))

    m = _RX["haste"].search(text)
    if m:
        a.haste_gear = int(m.group(1))
        a.haste_magic = int(m.group(2))
        a.haste_ability = int(m.group(3))

    m = _RX["tempo"].search(text)
    if m:
        a.dual_wield, a.store_tp, a.tp_bonus = (
            int(m.group(1)), int(m.group(2)), int(m.group(3)))

    m = _RX["wsdmg"].search(text)
    if m:
        a.ws_dmg_all, a.ws_dmg_first = int(m.group(1)), int(m.group(2))

    return a


def parse_anchor_file(path: str | Path) -> Anchor:
    return parse_anchor_text(Path(path).read_text(encoding="utf-8", errors="replace"))


def anchor_is_complete(a: Anchor) -> list[str]:
    """Return a list of human-readable warnings for missing critical fields."""
    warn = []
    if not a.stats.get("STR"):
        warn.append("STR/attributes block not found")
    if a.att == 0:
        warn.append("Melee ATT not found")
    if a.acc == 0:
        warn.append("Melee ACC not found")
    return warn
