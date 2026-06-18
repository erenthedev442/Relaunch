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
            "cluster. Talk to it to browse the Prime weapons; you only need to "
            "bring a voucher when you're ready to claim one.")


def _render_cost(c: dict) -> str:
    return (f"Each weapon costs **1 {c['voucher']}**. The Armory takes the "
            f"voucher and hands over the weapon you confirmed — one voucher, one "
            f"Prime weapon. Vouchers are earned through the Prime Voucher system, "
            f"so every Prime weapon you add to your arsenal is a milestone.\n\n"
            f"Make sure you have a free inventory slot before you confirm, or the "
            f"Armory won't be able to hand the weapon over.")


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
            "skill before deciding. The voucher is only spent on the final "
            "confirm, so take your time picking the right Prime weapon for your "
            "job.")


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
