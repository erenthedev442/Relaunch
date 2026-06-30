"""Sync docs/endgame/the-gauntlet.md with gauntlet_catalog.lua.

The Gauntlet is a 10-level solo challenge where HP doubles each level.
Parses the catalog so re-tuning HP, rewards, or NM names auto-updates the page.

Markers written:
  gauntlet-levels   — 10-level NM roster with mob level + HP
  gauntlet-rewards  — clear-10 reward table
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import commafy


def _first(pattern: str, text: str, default: str) -> str:
    m = re.search(pattern, text)
    return m.group(1) if m else default


def _int(pattern: str, text: str, default: int) -> int:
    return int(float(_first(pattern, text, str(default))))


def _parse(text: str) -> dict:
    c: dict = {}

    c["base_hp"] = _int(r"NM_BASE_HP\s*=\s*(\d+)", text, 20000)

    # Level formula: return BASE + level * MULT
    lv_base = _int(r"return\s+(\d+)\s*\+\s*level\s*\*\s*\d+", text, 72)
    lv_mult = _int(r"return\s+\d+\s*\+\s*level\s*\*\s*(\d+)", text, 8)
    c["lv_base"] = lv_base
    c["lv_mult"] = lv_mult

    # NM pool: [level] = { ..., name = 'Name' }
    nms: dict[int, str] = {}
    for m in re.finditer(r"\[(\d+)\]\s*=\s*\{[^}]*name\s*=\s*'([^']+)'", text):
        nms[int(m.group(1))] = m.group(2)
    c["nms"] = nms

    # Final reward
    rw_blk = re.search(r"FINAL_REWARD\s*=\s*\{([^}]*)\}", text)
    blk = rw_blk.group(1) if rw_blk else ""
    c["gil"]    = _int(r"gil\s*=\s*(\d+)", blk, 5000000)
    c["pp"]     = _int(r"\bpp\s*=\s*(\d+)", blk, 500)
    c["infamy"] = _int(r"infamy\s*=\s*(\d+)", blk, 500)

    return c


def _render_levels(c: dict) -> str:
    base_hp  = c["base_hp"]
    lv_base  = c["lv_base"]
    lv_mult  = c["lv_mult"]
    nms      = c["nms"]
    n_levels = max(nms.keys()) if nms else 10

    lines = [
        "| Level | NM | Mob level | HP |",
        "|---:|---|---:|---:|",
    ]
    for lv in range(1, n_levels + 1):
        name    = nms.get(lv, f"Level {lv} NM")
        mob_lv  = lv_base + lv * lv_mult
        hp      = base_hp * (2 ** (lv - 1))
        suffix  = " *(mandatory)*" if lv == n_levels else ""
        lines.append(f"| {lv} | **{name}**{suffix} | {mob_lv} | {commafy(hp)} |")

    mid_lv  = n_levels // 2 + 1
    mid_hp  = base_hp * (2 ** (mid_lv - 1))
    fold    = 2 ** (mid_lv - 1)
    lines.append("")
    lines.append(f"HP **doubles** every level — a level {mid_lv} {nms.get(mid_lv, 'NM')} "
                 f"has {fold:,}× the HP of the level 1 {nms.get(1, 'NM')}.")
    return "\n".join(lines)


def _render_rewards(c: dict) -> str:
    gil_str = commafy(c["gil"])
    gil_m   = c["gil"] // 1_000_000
    lines = [
        "| Reward | Amount |",
        "|---|---:|",
        f"| **Gil** | {gil_str} ({gil_m}M) |",
        f"| **Paragon Points** | {c['pp']:,} |",
        f"| **Infamy** | {c['infamy']:,} |",
        "| **Hall of Champions NPC** | Permanent |",
    ]
    return "\n".join(lines)


def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/gauntlet_catalog.lua")
    if src is None:
        print("[gauntlet] skip: gauntlet_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    c = _parse(text)

    page = docs_dir / "endgame" / "the-gauntlet.md"
    if not page.exists():
        print(f"[gauntlet] skip: {page} not found")
        return

    blocks = [
        ("gauntlet-levels",  _render_levels(c)),
        ("gauntlet-rewards", _render_rewards(c)),
    ]
    written = sum(1 for marker, content in blocks if write_between_markers(page, marker, content))
    print(f"[gauntlet] {written}/{len(blocks)} marker block(s) written "
          f"(nms={len(c['nms'])}, base_hp={c['base_hp']:,})")
