"""Generate docs/progression/aeonic-weapons.md from Temprix_NPC.lua.

The Aeonic weapon path: Temprix (Reisenjima) sells 14 "Malformed" base weapons
for Escha Beads; you forge a Malformed into a full Aeonic 119III at the Weapon
Forger in Leafallia with the matching Attestation + Riftborn Boulders (both from
Escha Geas Fete). Reads Temprix's weapon catalog + bead cost from the Lua.

Marker IDs: aeonic-overview, aeonic-weapons
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers

# Final Aeonic 119III weapon per type (retail names), for the reward column.
_AEONIC = {
    "Hand-to-Hand": "Godhands", "Dagger": "Aeneas", "Sword": "Sequence",
    "Gt. Sword": "Lionheart", "Axe": "Tri-edge", "Gt. Axe": "Chango",
    "Scythe": "Anguta", "Polearm": "Trishula", "Katana": "Heishi Shorinken",
    "Gt. Katana": "Dojikiri Yasutsuna", "Club": "Tishtrya", "Staff": "Khatvanga",
    "Archery": "Fail-not", "Marksmanship": "Fomalhaut",
}


def _parse(text: str) -> dict:
    m = re.search(r"COST\s*=\s*(\d+)", text)
    cost = int(m.group(1)) if m else 0
    weapons = []
    for m in re.finditer(
        r"name\s*=\s*'([^']+)'\s*,\s*id\s*=\s*(\d+)\s*,\s*wtype\s*=\s*'([^']+)'[^}\n]*?attName\s*=\s*'([^']+)'",
        text,
    ):
        weapons.append({"name": m.group(1), "wtype": m.group(3), "att": m.group(4)})
    return {"cost": cost, "weapons": weapons}


def _overview(c: dict) -> str:
    return (
        "**Aeonic** weapons (the 119III relics — Godhands, Aeneas, Sequence…) are the top melee reward "
        "on relaunch, forged in three steps:\n\n"
        f"1. **Buy a Malformed base weapon** from <!--npc:temprix-->Temprix in Reisenjima<!--/npc--> for "
        f"**{c['cost']:,} Escha Beads**.\n"
        "2. **Farm your Attestation + Riftborn Boulders** from [Escha Geas Fete](../endgame/geas-fete.md) "
        "— bosses drop the weapon-type Attestation; every tier drops Riftborn Boulders.\n"
        "3. **Forge** the Malformed weapon into its full Aeonic at the **Weapon Forger in Leafallia**.\n\n"
        "Escha Beads come from *any* Escha Geas Fete kill, so the whole path is fuelled by one currency."
    )


def _weapons(c: dict) -> str:
    lines = ["| Weapon type | Malformed base | Attestation | → Aeonic |", "|---|---|---|---|"]
    for w in c["weapons"]:
        lines.append(f"| {w['wtype']} | {w['name']} | {w['att']} | **{_AEONIC.get(w['wtype'], '—')}** |")
    return "\n".join(lines)


def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/Temprix_NPC.lua")
    if src is None:
        print("[aeonic_weapons] skip: Temprix_NPC.lua not found")
        return
    c = _parse(src.read_text(encoding="utf-8", errors="replace"))
    page = docs_dir / "progression" / "aeonic-weapons.md"
    page.parent.mkdir(parents=True, exist_ok=True)
    blocks = [("aeonic-overview", _overview(c)), ("aeonic-weapons", _weapons(c))]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[aeonic_weapons] {written}/{len(blocks)} blocks ({len(c['weapons'])} weapons, {c['cost']} beads each)")
