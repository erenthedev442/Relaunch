"""Sync docs/progression/prime-armory.md with the Prime Armory NPC.

The Prime weapons are defined inline in PrimeArmory_NPC.lua as a `WEAPONS`
table of `{ id, name, ws, info }` rows. We surface the player-facing fields
only — weapon name, its weapon type (the lead-in of `info`), and its weapon
skill. The raw item `id` is never published. Adding a weapon to the table
updates the page and the headline count automatically.

Markers written:
  prime-armory-access   — NPC + zone line
  prime-armory-cost     — voucher cost + how vouchers are obtained
  prime-armory-weapons  — the 12-weapon table (name / type / weapon skill)
  prime-armory-claim    — page-and-confirm flow note
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section


def _weapon_type(info: str) -> str:
    """The weapon type is the first sentence of `info` (up to the first '.').

    e.g. 'Hand-to-Hand. STR/DEX, ...' -> 'Hand-to-Hand'. Falls back to the
    whole string if there's no period.
    """
    head = info.split(".", 1)[0].strip()
    return head or info.strip()


def _parse(text: str) -> dict:
    c: dict = {"weapons": [], "voucher": "Prime Voucher"}

    block = section(text, "WEAPONS") or text
    # Each row: { id = N, name = '...', ws = '...', info = '...' }.
    row_re = re.compile(
        r"name\s*=\s*'([^']+)'\s*,\s*ws\s*=\s*'([^']+)'\s*,\s*info\s*=\s*'([^']+)'"
    )
    for m in row_re.finditer(block):
        name, ws, info = m.group(1), m.group(2), m.group(3)
        c["weapons"].append({
            "name": name,
            "ws": ws,
            "type": _weapon_type(info),
        })
    return c


# ---------------------------------------------------------------------------

def _render_access(c: dict) -> str:
    return ("The **Prime Armory** is in **GM Home**, just south of the Unlocker "
            "cluster. Talk to it to browse the Prime weapons; bring your **750M "
            "gil** when you're ready to forge (all 5 trials, including the "
            "voucher turn-in, must already be done).")


def _render_cost(c: dict) -> str:
    return ("Forging a Prime takes two things: **all 5 Prime Weapon Trials** "
            "([see the trials](prime-trials.md)) complete — Trial 3 is where your "
            "single **" + c['voucher'] + "** is consumed — and **750,000,000 gil** "
            "paid at the forge. You claim **one Prime weapon per character**, so "
            "choose the one that fits your main job.\n\n"
            "Make sure you have the gil and a free inventory slot before you "
            "confirm, or the Armory won't be able to hand the weapon over.")


def _render_weapons(c: dict) -> str:
    lines = [
        f"All **{len(c['weapons'])} Prime weapons**, one per weapon type:",
        "",
        "| Prime weapon | Weapon type | Weapon skill |",
        "|---|---|---|",
    ]
    for w in c["weapons"]:
        lines.append(f"| **{w['name']}** | {w['type']} | {w['ws']} |")
    return "\n".join(lines)


def _render_claim(c: dict) -> str:
    return ("Browsing is free — you can read every weapon's stats and weapon "
            "skill before deciding. The **750M gil** is only spent on the final "
            "confirm, so take your time picking the right Prime weapon for your "
            "job — you only claim one.")


# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/PrimeArmory_NPC.lua")
    if src is None:
        print("[prime_armory] skip: PrimeArmory_NPC.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    c = _parse(text)

    page = docs_dir / "progression" / "prime-armory.md"
    blocks = [
        ("prime-armory-access", _render_access(c)),
        ("prime-armory-cost", _render_cost(c)),
        ("prime-armory-weapons", _render_weapons(c)),
        ("prime-armory-claim", _render_claim(c)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[prime_armory] {written}/{len(blocks)} marker block(s) written "
          f"(weapons={len(c['weapons'])})")
