"""Generate key-facts table for docs/endgame/maats-challenge.md.

Reads: modules/custom/lua/maat_infamy_fight.lua

Marker IDs:
  - "maat-stats" -- entry cost, fight level, drop chance
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers


def _int_local(text: str, name: str) -> int | None:
    m = re.search(rf'\blocal\s+{re.escape(name)}\s*=\s*(\d+)', text)
    return int(m.group(1)) if m else None


def _float_local(text: str, name: str) -> float | None:
    m = re.search(rf'\blocal\s+{re.escape(name)}\s*=\s*([\d.]+)', text)
    return float(m.group(1)) if m else None


def _render_stats(cost: int, level: int, drop_pct: int) -> str:
    lines = [
        "| Stat | Value |",
        "|---|---|",
        f"| Entry cost | **{cost} Infamy** |",
        f"| Maat's level | **{level}** |",
        f"| Maat's Cap drop chance | **{drop_pct}%** |",
        "| Entry NPC | **Maat's Echo** — Ru'Lude Gardens |",
        "| Fight zone | **Waughroon Shrine** |",
        "| Simultaneous fights | Unlimited — every challenger gets their own |",
    ]
    return "\n".join(lines)


def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/maat_infamy_fight.lua")
    if src is None:
        print("[maats_challenge] skip: maat_infamy_fight.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")

    page = docs_dir / "endgame" / "maats-challenge.md"
    if not page.exists():
        print(f"[maats_challenge] skip: target page {page} not found")
        return

    cost     = _int_local(text,   "INFAMY_COST") or 50
    level    = _int_local(text,   "MAAT_LEVEL")  or 250
    drop_raw = _float_local(text, "DROP_CHANCE") or 0.25
    drop_pct = round(drop_raw * 100)

    content = _render_stats(cost, level, drop_pct)
    wrote = write_between_markers(page, "maat-stats", content)
    if wrote:
        print("[maats_challenge] stats: written into marker")
    else:
        print(f"[maats_challenge] stats: marker 'maat-stats' not found in {page.name}")
