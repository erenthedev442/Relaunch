"""Sync docs/progression/capacity-farm.md with the Capacity Point farm catalogs.

There are TWO permanent, always-up Capacity Point camps, each a fixed pool of
high-level phantoms that automatically respawn after a short delay:
  * Bibiki Bay            (!capacity) — capacity_farm_catalog.lua
  * King Ranperre's Tomb  (!ranperre) — ranperre_farm_catalog.lua
Both catalogs share the same shape, so everything on the page — each warp, the
mob name / level range / pool size, the bonus CP per kill, and the no-loot rule
— is read from the catalogs so re-tuning a camp updates the published guide.

Markers written:
  capacity-farm-access  — the warp commands + zones (one line per camp)
  capacity-farm-mobs    — the mob pool (name / count / level range / respawn)
  capacity-farm-rewards — bonus CP per kill + how the chain pays out
  capacity-farm-notes   — no loot/gil + eligibility caveats
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section, commafy


# Map the `xi.zone.FOO` symbol used in the catalog to a display name. The
# catalog stores zonePath = 'xi.zones.Bibiki_Bay', so the tail (underscores ->
# spaces) is the human name without hard-coding it here.
def _zone_name(text: str) -> str:
    m = re.search(r"zonePath\s*=\s*'xi\.zones\.([^']+)'", text)
    if m:
        return m.group(1).replace("_", " ")
    return "Bibiki Bay"


def _first(pattern: str, text: str, default: str) -> str:
    m = re.search(pattern, text)
    return m.group(1) if m else default


def _parse(text: str, command: str) -> dict:
    c: dict = {}

    c["zone"] = _zone_name(text)
    c["command"] = command   # the warp command (modules/custom/commands/<cmd>.lua)

    c["mobName"] = _first(r"catalog\.mobName\s*=\s*'([^']+)'", text, "Capacity Phantom")
    c["mobCount"] = int(float(_first(r"catalog\.mobCount\s*=\s*(\d+)", text, "100")))
    c["minLv"] = int(float(_first(r"catalog\.minLv\s*=\s*(\d+)", text, "150")))
    c["maxLv"] = int(float(_first(r"catalog\.maxLv\s*=\s*(\d+)", text, "160")))
    c["respawnSeconds"] = int(float(_first(r"catalog\.respawnSeconds\s*=\s*(\d+)", text, "5")))
    c["cpBonus"] = int(float(_first(r"catalog\.cpBonus\s*=\s*(\d+)", text, "0")))

    # NO_DROPS is set on every camp mob (CapacityFarm.lua) — the "CP only, no
    # loot/gil" rule. Detected from the catalog's own design comment so the page
    # reflects the camp's intent rather than a hard-coded claim.
    c["noLoot"] = bool(re.search(r"no\s+loot/gil", text, re.IGNORECASE))

    # The variety pool the camp draws models from (templates list). Player-facing
    # only as a count of "looks", so the camp isn't all one model.
    templates = section(text, "catalog.templates")
    c["templateCount"] = len(re.findall(r"\b\d{4,5}\b", templates)) if templates else 0
    return c


# ---------------------------------------------------------------------------

def _render_access(camps: list) -> str:
    lines = ["There are two always-up Capacity Point camps — warp to either from "
             "anywhere. Both are open to every player, no flags or quests, so you "
             "can drop in, grind a chain, and warp out whenever you like.", ""]
    for c in camps:
        lines.append(f"- Type **`{c['command']}`** to warp to the camp in "
                     f"**{c['zone']}**.")
    return "\n".join(lines)


def _render_mobs(camps: list) -> str:
    lines = []
    lines.append("Each camp keeps a persistent pool of **"
                 f"{camps[0]['mobName']}** monsters. A defeated phantom automatically "
                 f"returns **{camps[0]['respawnSeconds']} seconds after its death/despawn "
                 "sequence**, reusing the same entity slot so repeated farming cannot "
                 "exhaust the zone's dynamic IDs.")
    lines.append("")
    lines.append("| Camp | Warp | Pool | Levels |")
    lines.append("|---|---|---|---|")
    for c in camps:
        looks = (f"{c['mobCount']} phantoms, {c['templateCount']} looks"
                 if c["templateCount"] > 1 else f"{c['mobCount']} phantoms")
        lines.append(f"| {c['zone']} | `{c['command']}` | {looks} "
                     f"| Lv{c['minLv']}-{c['maxLv']} |")
    lines.append("")
    lines.append("Claim is shared free-for-all — everyone at the camp can fight "
                 "every monster, and the killer's alliance earns the Capacity "
                 "Points. Bring a party, bring trusts, or solo it; each pool is "
                 "sized to stay dense without ever running dry.")
    return "\n".join(lines)


def _render_rewards(camps: list) -> str:
    lines = []
    lines.append("Every phantom is a full Capacity Point kill. Because the pool is "
                 "large and the mobs automatically respawn, you can keep the engine's capacity "
                 "chain hot the whole time — back-to-back kills inside the chain "
                 "window stack the usual chain bonus on top of each award.")
    bonuses = {c["cpBonus"] for c in camps if c["cpBonus"] > 0}
    if len(bonuses) == 1:
        lines.append("")
        lines.append(f"On top of the normal level-based award, each kill pays a "
                     f"**flat {commafy(bonuses.pop())} bonus Capacity Points** to "
                     f"the killer (scaled by the server's Capacity rate, same as "
                     f"every other source).")
    elif len(bonuses) > 1:
        lines.append("")
        lines.append("On top of the normal level-based award, each kill pays a "
                     "flat bonus Capacity Points to the killer (scaled by the "
                     "server's Capacity rate):")
        lines.append("")
        for c in camps:
            if c["cpBonus"] > 0:
                lines.append(f"- **{c['zone']}** — +{commafy(c['cpBonus'])} CP per kill.")
    lines.append("")
    lines.append("After every modifier and server rate, a single mob can award at most "
                 "**60,000 Capacity Points** to one player. Since 30,000 CP still converts "
                 "to one Job Point, a sufficiently boosted kill can award **two Job Points**.")
    return "\n".join(lines)


def _render_notes(camps: list) -> str:
    lines = []
    if any(c["noLoot"] for c in camps):
        lines.append("- **No loot, no gil.** The phantoms drop nothing — these are "
                     "pure Capacity Point camps, not gear or gil farms.")
    lines.append("- **Capacity Points only.** The level range is well above the "
                 "Lv100 floor that makes a mob CP-eligible, so every kill counts "
                 "toward your Job Points once you've earned Job Points access.")
    lines.append("- **Always on.** Each camp is seeded when its zone wakes; its persistent "
                 "phantoms then respawn through the engine and zone-in/hourly checks replace "
                 "any genuinely missing entities, so both are "
                 "ready around the clock with no GM intervention.")
    return "\n".join(lines)


# ---------------------------------------------------------------------------

_PAGE = """# Capacity Point Farms

Job Points are a long grind, and Vana'diel's wild capacity mobs are scattered
and slow to respawn. The **Capacity Point Farms** fix that: two permanent,
always-up camps of high-level phantoms that die fast and automatically return.

!!! tip "Summary"
    Type `!capacity` (Bibiki Bay) or `!ranperre` (King Ranperre's Tomb) to warp
    to an always-up Capacity Point camp — a pool of {mobCount} {mobName}
    (Lv{minLv}-{maxLv}) that automatically respawn. Shared claim, no loot or
    gil, just Capacity Points.

## Getting there

<!-- DOCGEN:BEGIN id="capacity-farm-access" -->
<!-- DOCGEN:END id="capacity-farm-access" -->

## The camps

<!-- DOCGEN:BEGIN id="capacity-farm-mobs" -->
<!-- DOCGEN:END id="capacity-farm-mobs" -->

## What you earn

<!-- DOCGEN:BEGIN id="capacity-farm-rewards" -->
<!-- DOCGEN:END id="capacity-farm-rewards" -->

## Good to know

<!-- DOCGEN:BEGIN id="capacity-farm-notes" -->
<!-- DOCGEN:END id="capacity-farm-notes" -->

Capacity Points feed your Job Points, so park here whenever you want to push a
job's gifts and Job Point categories — the chain stays hot as long as you keep
swinging.
"""


# The two Capacity Point camps, in display order. Each: (catalog path, warp command).
_CAMPS = [
    ("modules/custom/lua/capacity_farm_catalog.lua", "!capacity"),
    ("modules/custom/lua/ranperre_farm_catalog.lua", "!ranperre"),
]


def generate(repo_root: Path, docs_dir: Path) -> None:
    camps = []
    for rel, command in _CAMPS:
        src = resolve_source(repo_root, rel)
        if src is None:
            print(f"[capacity-farm] skip camp: {rel} not found")
            continue
        camps.append(_parse(src.read_text(encoding="utf-8", errors="replace"), command))

    if not camps:
        print("[capacity-farm] skip: no camp catalogs found")
        return

    page = docs_dir / "progression" / "capacity-farm.md"
    if not page.exists():
        page.parent.mkdir(parents=True, exist_ok=True)
        c0 = camps[0]
        page.write_text(
            _PAGE.format(
                mobCount=c0["mobCount"],
                mobName=c0["mobName"],
                minLv=c0["minLv"],
                maxLv=c0["maxLv"],
            ),
            encoding="utf-8",
        )

    blocks = [
        ("capacity-farm-access", _render_access(camps)),
        ("capacity-farm-mobs", _render_mobs(camps)),
        ("capacity-farm-rewards", _render_rewards(camps)),
        ("capacity-farm-notes", _render_notes(camps)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[capacity-farm] {written}/{len(blocks)} marker block(s) written "
          f"({len(camps)} camp(s): "
          f"{', '.join(c['zone'] + ' ' + c['command'] for c in camps)})")
