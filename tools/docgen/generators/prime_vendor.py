"""Sync docs/progression/prime-vendor.md with the Prime Vendor NPC.

The Prime Vendor hands out the 16 *retail* Prime weapons in their final
"Level 119 III" forms. They are defined inline in PrimeVendor_NPC.lua as a
`WEAPONS` table of `{ id, name, type }` rows — we surface the player-facing
fields (weapon name and its weapon type); the raw item `id` is never published.
Purchase is gated behind the four Prime Weapon Trials (the `TRIAL_VARS` charVars
shared with the Prime Armory), so the weapons themselves are handed over free.
Adding a weapon to the table updates the page and the headline count
automatically.

Markers written:
  prime-vendor-access   — NPC + zone line
  prime-vendor-gate     — the four-trial gate (the trials are the cost)
  prime-vendor-weapons  — the 16-weapon table (name / weapon type)
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section


def _parse(text: str) -> dict:
    c: dict = {"weapons": [], "trials": 0}

    block = section(text, "WEAPONS") or text
    # Each row: { id = N, name = '...', type = '...' }.
    row_re = re.compile(
        r"name\s*=\s*'([^']+)'\s*,\s*type\s*=\s*'([^']+)'"
    )
    for m in row_re.finditer(block):
        name, wtype = m.group(1), m.group(2)
        c["weapons"].append({"name": name, "type": wtype})

    # The trial gate: count the entries in TRIAL_VARS (PW_Trial1_Done..).
    trial_block = section(text, "TRIAL_VARS") or text
    c["trials"] = len(re.findall(r"PW_Trial\d+_Done", trial_block))
    return c


# ---------------------------------------------------------------------------

def _render_access(c: dict) -> str:
    return ("The **Prime Vendor** is in **GM Home**, alongside the Prime Armory. "
            "Talk to it once you've cleared the Prime Trials and pick the retail "
            "Prime weapon you want — there's nothing to trade, the weapon is "
            "handed straight over.")


def _render_gate(c: dict) -> str:
    n = c["trials"] or 4
    return (f"The Prime Vendor is gated behind the **{n} Prime Weapon Trials**. "
            f"Complete **all {n}** and the vendor opens; until then it turns you "
            f"away. There is no gil or voucher cost — the trials themselves are "
            f"the price, so every weapon here is **free** once you've earned the "
            f"right to it.\n\n"
            f"Each Prime weapon is **Rare/Ex**, so you can only hold one of each, "
            f"and you'll need a free inventory slot for the vendor to hand it "
            f"over.")


def _render_weapons(c: dict) -> str:
    lines = [
        f"All **{len(c['weapons'])} retail Prime weapons**, in their final "
        f'"Level 119 III" forms — one for every weapon type plus the shield:',
        "",
        "| Prime weapon | Weapon type |",
        "|---|---|",
    ]
    for w in c["weapons"]:
        lines.append(f"| **{w['name']}** | {w['type']} |")
    return "\n".join(lines)


# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/PrimeVendor_NPC.lua")
    if src is None:
        print("[prime_vendor] skip: PrimeVendor_NPC.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    c = _parse(text)

    page = docs_dir / "progression" / "prime-vendor.md"
    blocks = [
        ("prime-vendor-access", _render_access(c)),
        ("prime-vendor-gate", _render_gate(c)),
        ("prime-vendor-weapons", _render_weapons(c)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[prime_vendor] {written}/{len(blocks)} marker block(s) written "
          f"(weapons={len(c['weapons'])})")
