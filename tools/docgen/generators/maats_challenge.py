"""Generate key-facts table for docs/endgame/maats-challenge.md.

Reads: modules/custom/lua/maat_infamy_fight.lua

Marker IDs:
  - "maat-stats" -- entry cost, fight level, drop chances, despawn timing

The page's hand prose deliberately references "the stat table" instead of
restating these numbers, so a retune only has to land in one place.
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


def _voucher_chance(text: str) -> float | None:
    """The Prime Voucher roll is inline (`math.random() < 0.005`), gated on
    PW_Trial3_Done — grab the literal from that guard."""
    m = re.search(r"PW_Trial3_Done'\)\s*or\s*0\)\s*==\s*0\s*and\s*math\.random\(\)\s*<\s*([\d.]+)", text)
    return float(m.group(1)) if m else None


def _render_stats(cost: int, level: int, drop_pct: int,
                  voucher_pct: float | None, idle: int | None) -> str:
    lines = [
        "| Stat | Value |",
        "|---|---|",
        f"| Entry cost | **{cost} Infamy** |",
        f"| Maat's level | **{level}** |",
        f"| Maat's Cap drop chance | **{drop_pct}%** |",
    ]
    if voucher_pct is not None:
        lines.append(f"| Prime Voucher drop chance | **{voucher_pct:g}%** "
                     f"(until Prime Trial 3 is cleared) |")
    lines += [
        "| Entry NPC | **Maat's Echo** — Ru'Lude Gardens |",
        "| Fight zone | **Waughroon Shrine** |",
        "| Simultaneous fights | Unlimited — every challenger gets their own |",
    ]
    if idle is not None:
        lines.append(f"| Abandoned-fight despawn | ~**{idle} seconds** after "
                     f"the owner dies or leaves |")
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

    cost     = _int_local(text,   "INFAMY_COST")
    level    = _int_local(text,   "MAAT_LEVEL")
    drop_raw = _float_local(text, "DROP_CHANCE")
    if cost is None or level is None or drop_raw is None:
        print("[maats_challenge] PARSER REGRESSION -- INFAMY_COST/MAAT_LEVEL/"
              "DROP_CHANCE not found in maat_infamy_fight.lua; keeping "
              "published content")
        return
    drop_pct = round(drop_raw * 100)
    voucher  = _voucher_chance(text)
    voucher_pct = voucher * 100 if voucher is not None else None
    idle     = _int_local(text, "IDLE_LIMIT")

    content = _render_stats(cost, level, drop_pct, voucher_pct, idle)
    wrote = write_between_markers(page, "maat-stats", content)
    if wrote:
        print("[maats_challenge] stats: written into marker")
    else:
        print(f"[maats_challenge] stats: marker 'maat-stats' not found in {page.name}")
