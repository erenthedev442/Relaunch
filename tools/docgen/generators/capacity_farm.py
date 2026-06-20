"""Sync docs/progression/capacity-farm.md with capacity_farm_catalog.lua.

The Capacity Farm is a permanent, always-up Capacity Point camp in Bibiki Bay:
a fixed pool of high-level mobs that instant-respawn as they die, so the
capacity chain never lapses. Everything on the page — the warp, the mob name /
level range / pool size, the bonus CP per kill, and the no-loot rule — is read
from the catalog so re-tuning the camp updates the published guide.

Markers written:
  capacity-farm-access  — !capacity warp + zone line
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


def _parse(text: str) -> dict:
    c: dict = {}

    c["zone"] = _zone_name(text)
    c["command"] = "!capacity"   # the warp command (modules/custom/commands/capacity.lua)

    c["mobName"] = _first(r"catalog\.mobName\s*=\s*'([^']+)'", text, "Capacity Phantom")
    c["mobCount"] = int(float(_first(r"catalog\.mobCount\s*=\s*(\d+)", text, "100")))
    c["minLv"] = int(float(_first(r"catalog\.minLv\s*=\s*(\d+)", text, "150")))
    c["maxLv"] = int(float(_first(r"catalog\.maxLv\s*=\s*(\d+)", text, "160")))
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

def _render_access(c: dict) -> str:
    return (f"Type **`{c['command']}`** from anywhere to warp straight to the "
            f"Capacity Point farm in **{c['zone']}**. It is open to every player, "
            f"no flags or quests — the camp is always live, so you can drop in, "
            f"grind a chain, and warp out whenever you like.")


def _render_mobs(c: dict) -> str:
    lines = []
    lines.append(f"The camp keeps a pool of **{c['mobCount']}** always-up "
                 f"**{c['mobName']}** monsters standing by. They sit between "
                 f"**level {c['minLv']} and {c['maxLv']}**, and each one "
                 f"**instantly respawns the moment it dies** — kill one and a "
                 f"fresh phantom takes its place on the spot, so there is always "
                 f"a target and your capacity chain never lapses waiting on a pop.")
    if c["templateCount"] > 1:
        lines.append("")
        lines.append(f"The phantoms wear a rotating mix of **{c['templateCount']}** "
                     f"different monster looks, so the camp isn't a wall of "
                     f"identical models.")
    lines.append("")
    lines.append("Claim is shared free-for-all — everyone at the camp can fight "
                 "every monster, and the killer's alliance earns the Capacity "
                 "Points. Bring a party, bring trusts, or solo it; the pool is "
                 "sized to stay dense without ever running dry.")
    return "\n".join(lines)


def _render_rewards(c: dict) -> str:
    lines = []
    lines.append("Every phantom is a full Capacity Point kill. Because they die "
                 "fast and respawn instantly, you can keep the engine's capacity "
                 "chain hot the whole time — back-to-back kills inside the chain "
                 "window stack the usual chain bonus on top of each award.")
    if c["cpBonus"] > 0:
        lines.append("")
        lines.append(f"On top of the normal level-based award, each kill pays a "
                     f"**flat {commafy(c['cpBonus'])} bonus Capacity Points** to "
                     f"the killer (scaled by the server's Capacity rate, same as "
                     f"every other source).")
    return "\n".join(lines)


def _render_notes(c: dict) -> str:
    lines = []
    if c["noLoot"]:
        lines.append("- **No loot, no gil.** The phantoms drop nothing — this is "
                     "a pure Capacity Point camp, not a gear or gil farm.")
    lines.append("- **Capacity Points only.** The level range is well above the "
                 "Lv100 floor that makes a mob CP-eligible, so every kill counts "
                 "toward your Job Points once you've earned Job Points access.")
    lines.append("- **Always on.** The camp is seeded when the zone wakes and "
                 "tops itself back up on every kill and every zone-in, so it is "
                 "ready around the clock with no GM intervention.")
    return "\n".join(lines)


# ---------------------------------------------------------------------------

_PAGE = """# Capacity Point Farm

Job Points are a long grind, and Vana'diel's wild capacity mobs are scattered
and slow to respawn. The **Capacity Point Farm** fixes that: a permanent,
always-up camp of high-level phantoms in {zone} that die fast and pop back
instantly, so your capacity chain never goes cold.

!!! tip "Summary"
    Type `{command}` to warp to an always-up Capacity Point camp in {zone} —
    a pool of {mobCount} {mobName} (Lv{minLv}-{maxLv}) that instant-respawn on
    death. Shared claim, no loot or gil, just Capacity Points.

## Getting there

<!-- DOCGEN:BEGIN id="capacity-farm-access" -->
<!-- DOCGEN:END id="capacity-farm-access" -->

## The camp

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


def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/capacity_farm_catalog.lua")
    if src is None:
        print("[capacity-farm] skip: capacity_farm_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    c = _parse(text)

    page = docs_dir / "progression" / "capacity-farm.md"
    if not page.exists():
        page.parent.mkdir(parents=True, exist_ok=True)
        page.write_text(
            _PAGE.format(
                zone=c["zone"],
                command=c["command"],
                mobCount=c["mobCount"],
                mobName=c["mobName"],
                minLv=c["minLv"],
                maxLv=c["maxLv"],
            ),
            encoding="utf-8",
        )

    blocks = [
        ("capacity-farm-access", _render_access(c)),
        ("capacity-farm-mobs", _render_mobs(c)),
        ("capacity-farm-rewards", _render_rewards(c)),
        ("capacity-farm-notes", _render_notes(c)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[capacity-farm] {written}/{len(blocks)} marker block(s) written "
          f"(mobCount={c['mobCount']}, lv={c['minLv']}-{c['maxLv']}, "
          f"cpBonus={c['cpBonus']}, templates={c['templateCount']})")
