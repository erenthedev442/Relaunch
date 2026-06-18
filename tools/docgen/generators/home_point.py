"""Sync docs/economy/home-point.md with the GM Home Home Point crystal.

The crystal's destination list lives in gm_home_homepoint_catalog.lua as
`catalog.regions = { { name, dests = { ... } }, ... }`. We summarise it by
region rather than listing every stop: the page shows the region coverage and
the total destination count, so re-syncing the catalog updates the headline
number automatically.

Markers written:
  home-point-access        — crystal + zone line
  home-point-sethome       — what "set home point here" does
  home-point-destinations  — per-region coverage table + total count
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section, commafy


def _parse(text: str) -> dict:
    c: dict = {"regions": []}

    regions = section(text, "catalog.regions")
    # Walk each `{ name = '...', dests = { ... } }` region block in order.
    for m in re.finditer(r"name\s*=\s*(['\"])(.+?)\1", regions):
        name = m.group(2)
        # Slice this region's `dests = { ... }` starting at the name match so a
        # later region's dests can't bleed in.
        rest = regions[m.end():]
        dests = section(rest, "dests")
        count = len(re.findall(r"label\s*=", dests))
        c["regions"].append((name, count))

    c["total"] = sum(n for _, n in c["regions"])
    return c


# ---------------------------------------------------------------------------

def _render_access(c: dict) -> str:
    return ("The **Home Point** crystal sits in **GM Home**, in the travel-NPC "
            "cluster on the east side — alongside the other warp services. "
            "Using it is always **free**: no gil cost and no attunement, so "
            "every destination is open from your first visit.")


def _render_sethome(c: dict) -> str:
    return ("Choose **Set home point here** and GM Home becomes your home point — "
            "you'll return here whenever you're knocked out and raised, or any "
            "time you use a home-point warp. It also registers GM Home as a "
            "destination on the wider home-point network, so other crystals out "
            "in the world can send you back.")


def _render_destinations(c: dict) -> str:
    lines = [
        f"The crystal reaches **{c['total']} home points** spread across "
        f"**{len(c['regions'])} regions** — effectively the entire home-point "
        f"network in one place:",
        "",
        "| Region | Home points |",
        "|---|---:|",
    ]
    for name, n in c["regions"]:
        lines.append(f"| {name} | {n} |")
    lines.append(f"| **Total** | **{commafy(c['total'])}** |")
    return "\n".join(lines)


# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/gm_home_homepoint_catalog.lua")
    if src is None:
        print("[home_point] skip: gm_home_homepoint_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    c = _parse(text)

    page = docs_dir / "economy" / "home-point.md"
    blocks = [
        ("home-point-access", _render_access(c)),
        ("home-point-sethome", _render_sethome(c)),
        ("home-point-destinations", _render_destinations(c)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[home_point] {written}/{len(blocks)} marker block(s) written "
          f"(regions={len(c['regions'])}, destinations={c['total']})")
