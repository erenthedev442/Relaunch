"""Generate Tournament wave table inside docs/endgame/tournament.md.

Reads: modules/custom/lua/Tournament.lua

Marker IDs:
  - "tournament-waves"  -- 8-wave difficulty table
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers

# ---------------------------------------------------------------------------
# Parser
# ---------------------------------------------------------------------------


def _parse_waves(text: str) -> list[dict]:
    """Extract each wave entry from the WAVES table in Tournament.lua."""
    # Match entries like:
    #   { label = 'Wave 1',  count = 3, level = 110, hpMult = 6,   groups = { ... } },
    wave_re = re.compile(
        r'\{[^}]*label\s*=\s*[\'"]([^\'"]+)[\'"][^}]*count\s*=\s*(\d+)[^}]*'
        r'level\s*=\s*(\d+)[^}]*hpMult\s*=\s*(\d+)',
        re.DOTALL,
    )
    waves = []
    for m in wave_re.finditer(text):
        waves.append({
            'label':   m.group(1),
            'count':   int(m.group(2)),
            'level':   int(m.group(3)),
            'hp_mult': int(m.group(4)),
        })
    return waves


# ---------------------------------------------------------------------------
# Renderer
# ---------------------------------------------------------------------------


def _render_waves(waves: list[dict]) -> str:
    rows = ['| Wave | Mobs | Level | Difficulty |', '|---|---|---|---|']
    for w in waves:
        rows.append(
            f"| {w['label']} | {w['count']} | {w['level']} | ×{w['hp_mult']} |"
        )
    return '\n'.join(rows)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------


def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/Tournament.lua")
    if src is None:
        print("[tournament] skip: Tournament.lua not found")
        return

    page = docs_dir / "endgame" / "tournament.md"
    if not page.exists():
        print(f"[tournament] skip: {page} not found")
        return

    text  = src.read_text(encoding="utf-8", errors="replace")
    waves = _parse_waves(text)
    if not waves:
        print("[tournament] skip: no WAVES entries found in Tournament.lua")
        return

    wrote  = write_between_markers(page, "tournament-waves", _render_waves(waves))
    status = "written" if wrote else "MARKER NOT FOUND: tournament-waves"
    print(f"[tournament] tournament-waves: {status}")
