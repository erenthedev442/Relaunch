"""Authoritative modifier id <-> name map, parsed from scripts/enum/mod.lua.

The server defines every modifier id exactly once in that file (and asserts it
matches src/map/modifier.h). Parsing it at runtime means dpscalc never drifts
from the server's mod ids -- if a mod is renamed or renumbered, we pick it up
automatically.
"""
from __future__ import annotations

import re
from functools import lru_cache

from .db import REPO_ROOT

# Matches `    STORETP                 = 73,` style lines inside the xi.mod table.
# Leading identifier is ALL-CAPS (excludes `xi.mod =` and `--` comment lines);
# value is a plain integer literal.
_ENTRY_RE = re.compile(r"^\s*([A-Z][A-Z0-9_]*)\s*=\s*(\d+)\s*,?", re.MULTILINE)


@lru_cache(maxsize=1)
def name_to_id() -> dict[str, int]:
    path = REPO_ROOT / "scripts" / "enum" / "mod.lua"
    text = path.read_text(encoding="utf-8", errors="replace")
    # Only parse the xi.mod table body to avoid catching anything stray.
    start = text.find("xi.mod")
    if start != -1:
        text = text[start:]
    out: dict[str, int] = {}
    for m in _ENTRY_RE.finditer(text):
        out[m.group(1)] = int(m.group(2))
    if "STR" not in out or out.get("STR") != 8:
        raise RuntimeError(
            f"mod.lua parse looks wrong (STR={out.get('STR')!r}); "
            f"parsed {len(out)} entries from {path}"
        )
    return out


@lru_cache(maxsize=1)
def id_to_name() -> dict[int, str]:
    rev: dict[int, str] = {}
    for name, mid in name_to_id().items():
        rev.setdefault(mid, name)  # first name wins on id collisions
    return rev


def mid(name: str) -> int:
    """Mod id by name, e.g. mid('STORETP') -> 73. Raises on unknown name."""
    return name_to_id()[name]


def mname(mod_id: int) -> str:
    """Human name for a mod id, or 'MOD_<id>' if unknown."""
    return id_to_name().get(mod_id, f"MOD_{mod_id}")
