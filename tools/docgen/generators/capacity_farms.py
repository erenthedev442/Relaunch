"""Generate docs/progression/capacity-farms.md from the two CP-farm catalogs.

Relaunch runs two shared Capacity Point farm camps — Bibiki Bay and King
Ranperre's Tomb — each an always-up pool of Lv150-160 "Capacity Phantoms" that
automatically respawn. Reads the zone + mob name straight from each catalog so the
page reconciles.

Marker IDs: cp-overview, cp-camps
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers

# catalog file -> (display zone, access command)
_CAMPS = [
    ("modules/custom/lua/capacity_farm_catalog.lua",  "!capacity"),
    ("modules/custom/lua/ranperre_farm_catalog.lua",  "!ranperre"),
]


def _read(repo_root: Path, rel: str) -> str:
    p = resolve_source(repo_root, rel)
    return p.read_text(encoding="utf-8", errors="replace") if p else ""


def _zone(text: str) -> str:
    m = re.search(r"zonePath\s*=\s*'xi\.zones\.([^']+)'", text)
    return m.group(1).replace("_", " ") if m else "?"


def _mob(text: str) -> str:
    m = re.search(r"mobName\s*=\s*'([^']+)'", text)
    return m.group(1) if m else "Capacity Phantom"


def _overview() -> str:
    return (
        "Grinding **Capacity Points** for Job Points? Relaunch keeps two dedicated **CP farm camps** "
        "running around the clock. Each is a pool of **always-up Lv150-160 mobs** with low HP that "
        "**automatically respawn**, use **shared claim** (anyone can help, everyone gets credit), and drop "
        "**no loot** — pure, uninterrupted Capacity Point farming. Warp in with the command, pull, "
        "repeat. (CP is boosted server-wide, so a session here fills Job Points fast.)"
    )


def _camps(repo_root: Path) -> str:
    lines = ["| Camp | Zone | Mobs | Access |", "|---|---|---|---:|"]
    for rel, cmd in _CAMPS:
        t = _read(repo_root, rel)
        if not t:
            continue
        zone = _zone(t)
        lines.append(f"| {zone} | Lv150-160 | {_mob(t)} | `{cmd}` |")
    return "\n".join(lines)


def generate(repo_root: Path, docs_dir: Path) -> None:
    if resolve_source(repo_root, _CAMPS[0][0]) is None and resolve_source(repo_root, _CAMPS[1][0]) is None:
        print("[capacity_farms] skip: no CP-farm catalog found")
        return
    page = docs_dir / "progression" / "capacity-farms.md"
    page.parent.mkdir(parents=True, exist_ok=True)
    blocks = [("cp-overview", _overview()), ("cp-camps", _camps(repo_root))]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[capacity_farms] {written}/{len(blocks)} blocks written")
