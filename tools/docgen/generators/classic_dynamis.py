"""Generate docs/endgame/dynamis-classic.md — classic Dynamis on relaunch.

Classic Dynamis drops currency + reforge materials only (gear is scrubbed by
modules/custom/sql/dynamis_no_gear_drops.sql; the Reforge path is the gear
source). The page's centerpiece is the Dynamis-Beaucedine Attestation NM
chain, whose droplist rows are pinned by
modules/custom/sql/restore_dynamis_attestation_pops.sql (the guard this
generator reads, so page and DB can never disagree):

    Hydra Corps Fomors drop 5 Fortune-telling parchments (5%) ->
    trade to a ??? to force-pop one of 5 Fomor NMs ->
    each NM kill drops exactly one Attestation (even split) ->
    Attestations feed the Aeonic Weapon Forge (same items Geas Fete bosses drop).

Sources:
    modules/custom/sql/restore_dynamis_attestation_pops.sql  (drop rows: rates, items)
    sql/mob_groups.sql                                       (zone 134: name -> dropid)
    scripts/zones/Dynamis-Beaucedine/IDs.lua                 (QM table: parchment -> NM)
    sql/npc_list.sql                                         (??? positions)
    modules/custom/lua/weapon_forge_catalog.lua              (attestation -> Aeonic, forge qty)

Marker IDs: dynamis-classic-overview, dynamis-attestation-nms,
            dynamis-attestation-aeonic
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._bgwiki import urls_for_item

# Retail display names for the pop parchments (item_basic only has log names).
_PARCHMENTS = {
    3359: "Despot's Fortune-telling Parchment",
    3360: "Sadist's Fortune-telling Parchment",
    3361: "Villain's Fortune-telling Parchment",
    3362: "Deluder's Fortune-telling Parchment",
    3363: "Traitor's Fortune-telling Parchment",
}

# Attestations NOT consumed by the Aeonic forge (no matching weapon chain).
_NON_FORGE_ATTESTATIONS = {
    1570: "Attestation of Accuracy",
    1821: "Attestation of Invulnerability",
}

_ATTESTATION_IDS = set(range(1556, 1571)) | {1821}


def _parse_guard_sql(text: str) -> tuple[dict[int, int], dict[int, list[tuple[int, int]]]]:
    """-> (parchment dropId->itemId, NM dropId->[(attestation itemId, itemRate)])."""
    parchment_by_dropid: dict[int, int] = {}
    attestations_by_dropid: dict[int, list[tuple[int, int]]] = {}
    for m in re.finditer(
        r"INSERT INTO `mob_droplist` VALUES \((\d+),\d+,\d+,\d+,(\d+),(\d+)\);", text
    ):
        drop_id, item_id, item_rate = int(m.group(1)), int(m.group(2)), int(m.group(3))
        if item_id in _PARCHMENTS:
            parchment_by_dropid[drop_id] = item_id
        elif item_id in _ATTESTATION_IDS:
            attestations_by_dropid.setdefault(drop_id, []).append((item_id, item_rate))
    return parchment_by_dropid, attestations_by_dropid


def _parse_zone_groups(text: str) -> dict[str, list[int]]:
    """Zone 134 mob_groups -> {group name: [dropid, ...]} (a name can repeat)."""
    groups: dict[str, list[int]] = {}
    for m in re.finditer(r"VALUES \(\d+,\d+,134,'([^']+)',\d+,\d+,(\d+),", text):
        groups.setdefault(m.group(1), []).append(int(m.group(2)))
    return groups


def _parse_qm_table(text: str) -> dict[int, str]:
    """IDs.lua QM entries -> {parchment itemId: NM name} (from the comments)."""
    out: dict[int, str] = {}
    for m in re.finditer(
        r"trade = \{ \{ item = (\d+), mob = \d+ \} \} \},?\s*-- (\w+)", text
    ):
        item_id = int(m.group(1))
        if item_id in _PARCHMENTS:
            out[item_id] = m.group(2)
    return out


def _parse_qm_positions(text: str, qm_by_item: dict[int, str]) -> dict[str, str]:
    """npc_list qm5..qm9 (17326806-10) -> {NM name: '(x, z)'}.

    QM npcids are ordered like the IDs.lua QM table: 17326806..10 pop the NMs
    for parchments 3359..3363 respectively.
    """
    pos: dict[str, str] = {}
    for m in re.finditer(
        r"VALUES \((173268(?:06|07|08|09|10)),'qm\d','\?\?\?',\d+,"
        r"(-?[\d.]+),(-?[\d.]+),(-?[\d.]+),",
        text,
    ):
        item_id = 3359 + int(m.group(1)) - 17326806
        nm = qm_by_item.get(item_id)
        if nm:
            pos[nm] = f"({float(m.group(2)):.0f}, {float(m.group(4)):.0f})"
    return pos


def _parse_forge(text: str) -> tuple[dict[int, tuple[str, str, int]], int]:
    """-> ({attestationId: (attestation name, Aeonic name, Aeonic id)}, total attestations/weapon)."""
    forge: dict[int, tuple[str, str, int]] = {}
    for m in re.finditer(
        r"attestationId\s*=\s*(\d+)\s*,\s*attestationName\s*=\s*'([^']+)'\s*,"
        r"\s*s3\s*=\s*\{\s*id\s*=\s*(\d+)\s*,\s*name\s*=\s*'([^']+)'",
        text,
    ):
        forge[int(m.group(1))] = (m.group(2), m.group(4), int(m.group(3)))
    total = sum(int(q) for q in re.findall(r"attestations\s*=\s*(\d+)", text))
    return forge, total


def _item_link(name: str, item_id: int | None) -> str:
    """FFXIAH link with a data-img hover icon, matching the vendor tables."""
    page_url, image_url = urls_for_item(name, None, item_id=item_id)
    return (
        f'<a class="item-link" href="{page_url}" '
        f'data-img="{image_url}" target="_blank" rel="noopener">{name}</a>'
    )


def _attestation_name(item_id: int, forge: dict[int, tuple[str, str]]) -> str:
    if item_id in forge:
        return forge[item_id][0]
    return _NON_FORGE_ATTESTATIONS.get(item_id, f"item {item_id}")


def _fomor_jobs(parchment_id: int, parchment_by_dropid: dict[int, int],
                zone_groups: dict[str, list[int]]) -> str:
    drop_ids = {d for d, i in parchment_by_dropid.items() if i == parchment_id}
    jobs = sorted(
        name.replace("Hydra_", "").replace("_", " ")
        for name, dropids in zone_groups.items()
        if name.startswith("Hydra_") and any(d in drop_ids for d in dropids)
    )
    return ", ".join(jobs)


def generate(repo_root: Path, docs_dir: Path) -> None:
    srcs = {
        "guard": resolve_source(repo_root, "modules/custom/sql/restore_dynamis_attestation_pops.sql"),
        "groups": resolve_source(repo_root, "sql/mob_groups.sql"),
        "ids": resolve_source(repo_root, "scripts/zones/Dynamis-Beaucedine/IDs.lua"),
        "npcs": resolve_source(repo_root, "sql/npc_list.sql"),
        "forge": resolve_source(repo_root, "modules/custom/lua/weapon_forge_catalog.lua"),
    }
    missing = [k for k, v in srcs.items() if v is None]
    if missing:
        print(f"[classic_dynamis] skip: missing sources {missing}")
        return

    parchment_by_dropid, attestations_by_dropid = _parse_guard_sql(
        srcs["guard"].read_text(encoding="utf-8", errors="replace"))
    zone_groups = _parse_zone_groups(srcs["groups"].read_text(encoding="utf-8", errors="replace"))
    qm_by_item = _parse_qm_table(srcs["ids"].read_text(encoding="utf-8", errors="replace"))
    qm_pos = _parse_qm_positions(srcs["npcs"].read_text(encoding="utf-8", errors="replace"), qm_by_item)
    forge, per_weapon = _parse_forge(srcs["forge"].read_text(encoding="utf-8", errors="replace"))

    # NM -> its attestation droplist, via the NM's dropid in mob_groups.
    nm_rows = []
    for item_id, nm in sorted(qm_by_item.items()):
        nm_dropids = zone_groups.get(nm, [])
        atts = []
        for d in nm_dropids:
            atts.extend(attestations_by_dropid.get(d, []))
        if not atts:
            print(f"[classic_dynamis] WARNING: no attestation drop rows found for NM {nm}")
            continue
        nm_rows.append({
            "nm": nm,
            "parchment": _item_link(_PARCHMENTS[item_id], item_id),
            "jobs": _fomor_jobs(item_id, parchment_by_dropid, zone_groups),
            "pos": qm_pos.get(nm, "—"),
            "atts": [(i, _attestation_name(i, forge)) for i, _ in sorted(atts)],
        })
    if len(nm_rows) != len(_PARCHMENTS):
        print(f"[classic_dynamis] skip: expected {len(_PARCHMENTS)} NM chains, "
              f"resolved {len(nm_rows)} — refusing to publish a partial table")
        return

    parchment_rate = "5%"  # itemRate 50/1000 on every parchment row in the guard SQL

    overview = (
        "On relaunch, classic Dynamis drops **currency and reforge materials only** — "
        "all retail gear drops are removed (the [Reforge System](../progression/reforge.md) "
        "is the gear source, fed by the medals and materials these zones drop).\n\n"
        "The exception worth planning a run around is the **Attestation NM chain in "
        "Dynamis-Beaucedine**:\n\n"
        "1. Kill **Hydra Corps Fomors** — each job drops one of five *Fortune-telling "
        f"parchments* ({parchment_rate}, Rare).\n"
        "2. Trade the parchment to its **???** spot to force-pop the matching **Fomor NM**.\n"
        "3. The NM drops **exactly one Attestation per kill** (even split across its set).\n\n"
        "These are the **same Attestations the [Aeonic weapon](../progression/aeonic-weapons.md) "
        f"forge consumes** ({per_weapon} of one type per weapon) — so Dynamis-Beaucedine is a "
        "full alternative to farming [Geas Fete](geas-fete.md) bosses for them."
    )

    nm_lines = [
        "| Fomor NM | Pop item (5% drop) | Parchment drops from (Hydra Corps) | ??? spot `/pos` | Attestations (one per kill) |",
        "|---|---|---|---|---|",
    ]
    for r in nm_rows:
        atts = "<br>".join(f"• {_item_link(name, iid)}" for iid, name in r["atts"])
        nm_lines.append(
            f"| **{r['nm']}** | {r['parchment']} | {r['jobs']} | {r['pos']} | {atts} |"
        )

    aeonic_lines = [
        "| Attestation | Dropped by | Feeds Aeonic |",
        "|---|---|---|",
    ]
    nm_by_att: dict[int, str] = {}
    for r in nm_rows:
        for iid, _ in r["atts"]:
            nm_by_att[iid] = r["nm"]
    for att_id in sorted(_ATTESTATION_IDS):
        name = _attestation_name(att_id, forge)
        if att_id in forge:
            aeonic = f"**{_item_link(forge[att_id][1], forge[att_id][2])}**"
        else:
            aeonic = "— (no forge use)"
        aeonic_lines.append(
            f"| {_item_link(name, att_id)} | {nm_by_att.get(att_id, '—')} | {aeonic} |")

    page = docs_dir / "endgame" / "dynamis-classic.md"
    blocks = [
        ("dynamis-classic-overview", overview),
        ("dynamis-attestation-nms", "\n".join(nm_lines)),
        ("dynamis-attestation-aeonic", "\n".join(aeonic_lines)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[classic_dynamis] {written}/{len(blocks)} blocks ({len(nm_rows)} NM chains)")
