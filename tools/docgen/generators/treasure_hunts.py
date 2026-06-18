"""Sync docs/endgame/treasure-hunts.md with treasure_catalog.lua.

Hunting League kills can drop a treasure map; carry it to its overworld zone
and dig (hot/cold feedback) to find a buried strongbox. The drop rates, the
three map tiers, the dig zones, the temperature bands, and the per-tier loot
all come from the catalog so re-tuning the hunt updates the published guide.

Markers written:
  treasure-hunts-drops   — how maps drop + the three map tiers
  treasure-hunts-zones   — the dig-zone list
  treasure-hunts-dig     — the dig minigame + temperature bands
  treasure-hunts-loot    — the loot table per map tier
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section, ints, commafy


def _first(pattern: str, text: str, default: str) -> str:
    m = re.search(pattern, text)
    return m.group(1) if m else default


def _parse(text: str) -> dict:
    c: dict = {}

    drop = section(text, "catalog.drop")
    c["base"] = int(float(_first(r"basePct\s*=\s*([0-9.]+)", drop, "8")))
    c["perTier"] = int(float(_first(r"perTierPct\s*=\s*([0-9.]+)", drop, "2")))

    # Kill tier -> map tier mapping, e.g. { 1, 1, 2, 2, 3 }.
    mt = section(text, "catalog.mapTierForKillTier")
    c["killToMap"] = ints(mt)

    names = section(text, "catalog.mapNames")
    c["mapNames"] = {}
    for idx, name in re.findall(r"\[(\d+)\]\s*=\s*'([^']+)'", names):
        c["mapNames"][int(idx)] = name

    zones = section(text, "catalog.zones")
    c["zones"] = re.findall(r"label\s*=\s*'([^']+)'", zones)

    dig = section(text, "catalog.dig")
    c["digRadius"] = float(_first(r"successRadius\s*=\s*([0-9.]+)", dig, "12"))
    bands = section(dig, "bands")
    c["bands"] = re.findall(r"text\s*=\s*'([^']+)'", bands)

    loot = section(text, "catalog.loot")
    c["loot"] = {}
    for idx, body in re.findall(r"\[(\d+)\]\s*=\s*\{([^}]*)\}", loot):
        d = {}
        d["marks"] = int(float(_first(r"marks\s*=\s*([0-9.]+)", body, "0")))
        d["gil"] = int(float(_first(r"gil\s*=\s*([0-9.]+)", body, "0")))
        d["catalysts"] = int(float(_first(r"catalysts\s*=\s*([0-9.]+)", body, "0")))
        d["announce"] = "announce = true" in body
        c["loot"][int(idx)] = d
    return c


def _ordinal(n: int) -> str:
    return {1: "first", 2: "second", 3: "third", 4: "fourth", 5: "fifth"}.get(n, f"#{n}")


# ---------------------------------------------------------------------------

def _render_drops(c: dict) -> str:
    lines = []
    lines.append(f"Every Hunting League kill has a chance to shake loose a "
                 f"treasure map — **{c['base']}%** at the lowest hunt tier, rising "
                 f"**{c['perTier']}%** per tier (so a top-tier kill is around "
                 f"**{c['base'] + c['perTier'] * (len(c['killToMap']) - 1)}%**). "
                 f"You can only carry one map at a time, so dig up the one you "
                 f"have before going for another.")
    # Map tier -> which kill tiers produce it.
    tier_sources: dict[int, list[int]] = {}
    for kill_idx, map_tier in enumerate(c["killToMap"], start=1):
        tier_sources.setdefault(map_tier, []).append(kill_idx)
    if c["mapNames"]:
        lines.append("")
        lines.append("Tougher hunts drop better maps:")
        lines.append("")
        lines.append("| Map | Drops from |")
        lines.append("|---|---|")
        for tier in sorted(c["mapNames"]):
            name = c["mapNames"][tier]
            kills = tier_sources.get(tier, [])
            if kills:
                lo, hi = min(kills), max(kills)
                where = (f"the {_ordinal(lo)} hunt tier"
                         if lo == hi else
                         f"the {_ordinal(lo)}–{_ordinal(hi)} hunt tiers")
            else:
                where = "—"
            lines.append(f"| **{name}** | {where} |")
    return "\n".join(lines)


def _render_zones(c: dict) -> str:
    lines = []
    lines.append("A map points at one of the classic overworld zones. Travel to "
                 "the marked zone, then start digging:")
    lines.append("")
    for z in c["zones"]:
        lines.append(f"- {z}")
    return "\n".join(lines)


def _render_dig(c: dict) -> str:
    lines = []
    lines.append("Your **first dig** buries the strongbox somewhere nearby on "
                 "solid ground. Every dig after that gives you a temperature "
                 "reading and a compass nudge — follow the heat until you are "
                 "standing on top of it:")
    if c["bands"]:
        lines.append("")
        for b in c["bands"]:
            lines.append(f"- *{b}*")
    lines.append("")
    lines.append(f"Dig within about **{c['digRadius']:g} fulms** of the box and "
                 f"it's yours.")
    return "\n".join(lines)


def _render_loot(c: dict) -> str:
    lines = []
    lines.append("What's inside scales with the map's tier:")
    lines.append("")
    lines.append("| Map | Marks | Gil | Augment catalysts |")
    lines.append("|---|---:|---:|---:|")
    for tier in sorted(c["loot"]):
        d = c["loot"][tier]
        name = c["mapNames"].get(tier, f"Tier {tier}")
        cats = f"{d['catalysts']}"
        line = (f"| **{name}** | {commafy(d['marks'])} | {commafy(d['gil'])} "
                f"| {cats} |")
        lines.append(line)
    # Announce note for the top tier.
    top = max((t for t, d in c["loot"].items() if d["announce"]), default=None)
    if top is not None:
        name = c["mapNames"].get(top, f"Tier {top}")
        lines.append("")
        lines.append(f"Cracking open a **{name}** is announced server-wide — the "
                     f"whole world hears about your haul.")
    lines.append("")
    lines.append("Catalysts are the same ones used to power up augmented gear, so "
                 "the world tour keeps the augment economy fed.")
    return "\n".join(lines)


# ---------------------------------------------------------------------------

_PAGE = """# Treasure Hunts

Out in the field, a Hunting League kill might turn up a tattered map with an X
on it. Carry it to the right corner of the world, dig where it's warm, and pry
open a buried strongbox full of marks, gil, and augment catalysts.

!!! tip "Summary"
    Hunting League kills can drop treasure maps; take a map to its overworld
    zone and dig — hot/cold feedback guides you to a buried strongbox of marks,
    gil, and augment catalysts.

## Finding maps

<!-- DOCGEN:BEGIN id="treasure-hunts-drops" -->
<!-- DOCGEN:END id="treasure-hunts-drops" -->

## Where to dig

<!-- DOCGEN:BEGIN id="treasure-hunts-zones" -->
<!-- DOCGEN:END id="treasure-hunts-zones" -->

## The dig

<!-- DOCGEN:BEGIN id="treasure-hunts-dig" -->
<!-- DOCGEN:END id="treasure-hunts-dig" -->

## What's in the box

<!-- DOCGEN:BEGIN id="treasure-hunts-loot" -->
<!-- DOCGEN:END id="treasure-hunts-loot" -->

Keep an empty inventory slot or two before you dig — a strongbox that can't fit
all its catalysts pays you marks for the overflow instead.
"""


def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/treasure_catalog.lua")
    if src is None:
        print("[treasure-hunts] skip: treasure_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    c = _parse(text)

    page = docs_dir / "endgame" / "treasure-hunts.md"
    if not page.exists():
        page.parent.mkdir(parents=True, exist_ok=True)
        page.write_text(_PAGE, encoding="utf-8")

    blocks = [
        ("treasure-hunts-drops", _render_drops(c)),
        ("treasure-hunts-zones", _render_zones(c)),
        ("treasure-hunts-dig", _render_dig(c)),
        ("treasure-hunts-loot", _render_loot(c)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[treasure-hunts] {written}/{len(blocks)} marker block(s) written "
          f"(zones={len(c['zones'])}, tiers={len(c['mapNames'])}, "
          f"bands={len(c['bands'])})")
