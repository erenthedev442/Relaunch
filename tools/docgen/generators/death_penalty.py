"""Generate death penalty config table inside docs/progression/death-penalty.md.

Reads: modules/custom/lua/death_penalty.lua

Marker IDs:
  - "death-penalty-config" -- summary config table
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers

# ---------------------------------------------------------------------------
# Lua helpers (duplicated per the established pattern)
# ---------------------------------------------------------------------------

_QUOTED = r"""'(?:[^'\\]|\\.)*'|"(?:[^"\\]|\\.)*" """


def _quoted_value(s: str) -> str:
    s = s.strip()
    if (s.startswith("'") and s.endswith("'")) or (s.startswith('"') and s.endswith('"')):
        return s[1:-1]
    return s


def _balanced_blocks(text: str):
    """Yield (start, end) character offsets for every top-level {...} block."""
    depth = 0
    in_single = False
    in_double = False
    start = -1
    i = 0
    while i < len(text):
        c = text[i]
        if not in_single and not in_double and text[i:i+2] == '--':
            end_of_line = text.find('\n', i)
            i = end_of_line + 1 if end_of_line != -1 else len(text)
            continue
        if c == "'" and not in_double:
            in_single = not in_single
        elif c == '"' and not in_single:
            in_double = not in_double
        elif not in_single and not in_double:
            if c == '{':
                if depth == 0:
                    start = i
                depth += 1
            elif c == '}':
                depth -= 1
                if depth == 0 and start != -1:
                    yield (start, i + 1)
                    start = -1
        i += 1


# ---------------------------------------------------------------------------
# Parser
# ---------------------------------------------------------------------------

def _parse_int_local(text: str, varname: str) -> int | None:
    """Parse a top-level `local VARNAME = N` assignment."""
    m = re.search(rf'\blocal\s+{re.escape(varname)}\s*=\s*(\d+)', text)
    return int(m.group(1)) if m else None


# ---------------------------------------------------------------------------
# Renderer
# ---------------------------------------------------------------------------

def _render_config(penalty: int, exempt_kills: int) -> str:
    lines = [
        "| Setting | Value |",
        "|---|---|",
        f"| Mark loss per death | **−{penalty} Hunt Marks** |",
        "| Zone scope | Escha ZiTah only |",
        f"| New-player grace | Players with fewer than **{exempt_kills} NM kills** are exempt |",
        "| Floor | Balance never goes below zero |",
    ]
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/death_penalty.lua")
    if src is None:
        print("[death_penalty] skip: death_penalty.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")

    page = docs_dir / "progression" / "death-penalty.md"
    if not page.exists():
        print(f"[death_penalty] skip: target page {page} not found")
        return

    penalty      = _parse_int_local(text, "PENALTY")      or 10
    exempt_kills = _parse_int_local(text, "EXEMPT_KILLS") or 50

    config_content = _render_config(penalty, exempt_kills)
    wrote = write_between_markers(page, "death-penalty-config", config_content)
    if wrote:
        print("[death_penalty] config: written into marker")
    else:
        print(f"[death_penalty] config: marker 'death-penalty-config' not found in {page.name}")
