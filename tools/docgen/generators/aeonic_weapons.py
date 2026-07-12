"""Generate docs/progression/aeonic-weapons.md from Temprix_NPC.lua.

The Aeonic weapon path: Temprix (Reisenjima) sells 14 "Malformed" base weapons
for Escha Beads; you forge a Malformed into a full Aeonic 119III at the Weapon
Forger (zone injected via {{npc:weapon_forger}}) with the matching Attestation +
Riftborn Boulders (both from
Escha Geas Fete). Reads Temprix's weapon catalog + bead cost from the Lua;
item ids for the Attestation and final Aeonic come from
weapon_forge_catalog.lua so every item renders as an FFXIAH link with a
hover icon (same _bgwiki.urls_for_item treatment as the vendor pages).

Marker IDs: aeonic-overview, aeonic-weapons
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._bgwiki import urls_for_item

# Final Aeonic 119III weapon per type (retail names) — fallback when a chain
# is missing from weapon_forge_catalog.lua.
_AEONIC = {
    "Hand-to-Hand": "Godhands", "Dagger": "Aeneas", "Sword": "Sequence",
    "Gt. Sword": "Lionheart", "Axe": "Tri-edge", "Gt. Axe": "Chango",
    "Scythe": "Anguta", "Polearm": "Trishula", "Katana": "Heishi Shorinken",
    "Gt. Katana": "Dojikiri Yasutsuna", "Club": "Tishtrya", "Staff": "Khatvanga",
    "Archery": "Fail-not", "Marksmanship": "Fomalhaut",
}


def _item_link(name: str, item_id: int | None) -> str:
    """FFXIAH link with a data-img hover icon, matching the vendor tables."""
    page_url, image_url = urls_for_item(name, None, item_id=item_id)
    return (
        f'<a class="item-link" href="{page_url}" '
        f'data-img="{image_url}" target="_blank" rel="noopener">{name}</a>'
    )


def _parse(text: str) -> dict:
    m = re.search(r"COST\s*=\s*(\d+)", text)
    cost = int(m.group(1)) if m else 0
    weapons = []
    for m in re.finditer(
        r"name\s*=\s*'([^']+)'\s*,\s*id\s*=\s*(\d+)\s*,\s*wtype\s*=\s*'([^']+)'[^}\n]*?attName\s*=\s*'([^']+)'",
        text,
    ):
        weapons.append({"name": m.group(1), "id": int(m.group(2)),
                        "wtype": m.group(3), "att": m.group(4)})
    return {"cost": cost, "weapons": weapons}


def _parse_chains(text: str) -> dict:
    """weapon_forge_catalog.lua -> {wtype: {attId, attName, aeonicId, aeonicName}}."""
    chains = {}
    for m in re.finditer(
        r"type\s*=\s*'([^']+)'.*?"
        r"attestationId\s*=\s*(\d+)\s*,\s*attestationName\s*=\s*'([^']+)'\s*,"
        r"\s*s3\s*=\s*\{\s*id\s*=\s*(\d+)\s*,\s*name\s*=\s*'([^']+)'",
        text, re.DOTALL,
    ):
        chains[m.group(1)] = {
            "attId": int(m.group(2)), "attName": m.group(3),
            "aeonicId": int(m.group(4)), "aeonicName": m.group(5),
        }
    return chains


def _overview(c: dict) -> str:
    return (
        "**Aeonic** weapons (the 119III relics — Godhands, Aeneas, Sequence…) are the top melee reward "
        "on relaunch, forged in three steps:\n\n"
        f"1. **Buy a Malformed base weapon** from Temprix in Reisenjima for "
        f"**{c['cost']:,} Escha Beads**.\n"
        "2. **Farm your Attestation + Riftborn Boulders** from [Escha Geas Fete](../endgame/geas-fete.md) "
        "— bosses drop the weapon-type Attestation; every tier drops Riftborn Boulders. Attestations "
        "also drop from the [Attestation NMs in classic Dynamis](../endgame/dynamis-classic.md).\n"
        "3. **Forge** the Malformed weapon into its full Aeonic at the **Weapon Forger** in "
        "{{npc:weapon_forger}}.\n\n"
        "Escha Beads come from *any* Escha Geas Fete kill, so the whole path is fuelled by one currency."
    )


# Temprix abbreviates the two-handed types; weapon_forge_catalog spells them out.
_WTYPE_ALIASES = {"Gt. Sword": "Great Sword", "Gt. Axe": "Great Axe", "Gt. Katana": "Great Katana"}


def _weapons(c: dict, chains: dict) -> str:
    lines = ["| Weapon type | Malformed base | Attestation | → Aeonic |", "|---|---|---|---|"]
    for w in c["weapons"]:
        chain = chains.get(w["wtype"]) or chains.get(_WTYPE_ALIASES.get(w["wtype"], ""), {})
        malformed = _item_link(w["name"], w["id"])
        att = _item_link(chain.get("attName", w["att"]), chain.get("attId"))
        aeonic_name = chain.get("aeonicName") or _AEONIC.get(w["wtype"], "—")
        aeonic = _item_link(aeonic_name, chain.get("aeonicId")) if aeonic_name != "—" else "—"
        lines.append(f"| {w['wtype']} | {malformed} | {att} | **{aeonic}** |")
    return "\n".join(lines)


def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/Temprix_NPC.lua")
    if src is None:
        print("[aeonic_weapons] skip: Temprix_NPC.lua not found")
        return
    c = _parse(src.read_text(encoding="utf-8", errors="replace"))
    forge = resolve_source(repo_root, "modules/custom/lua/weapon_forge_catalog.lua", required=False)
    chains = _parse_chains(forge.read_text(encoding="utf-8", errors="replace")) if forge else {}
    page = docs_dir / "progression" / "aeonic-weapons.md"
    page.parent.mkdir(parents=True, exist_ok=True)
    blocks = [("aeonic-overview", _overview(c)), ("aeonic-weapons", _weapons(c, chains))]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[aeonic_weapons] {written}/{len(blocks)} blocks "
          f"({len(c['weapons'])} weapons, {len(chains)} linked chains, {c['cost']} beads each)")
