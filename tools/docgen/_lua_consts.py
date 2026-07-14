"""Live-read Lua numeric constants — the ONE sanctioned way generators
reference a Lua-side tunable.

Why this exists
---------------
Doc generators kept hard-coding numbers that lived in Lua modules
(DROP_RATE, RUSTED_QTY, GILDROP_RATE, ...). When the Lua was tuned, the
generator's mirror stayed frozen and the docs shipped a wrong number
until a player complained. sync_audit's original `MIRROR-CONST` check
only matched by NAME (ALL_CAPS Python vs Lua local), so bare-literal
mirrors (`"pct": 50.0`), fallback defaults (`.get("rusted_qty", 12)`),
and rename-mirrors slipped through.

Rule
----
If a generator uses a numeric value that mirrors a Lua constant, it MUST
resolve it through this helper. The value is read at docgen time — no
Python-side cache, no possibility of drift.

`sync_audit._shadow_literals` scans generator source for suspicious
literals and warns unless a `lua_const(` call OR a `# @from-lua ...`
marker is on the same line.

Usage
-----
    from tools.docgen._lua_consts import lua_const

    drop_rate = lua_const(
        repo_root,
        'modules/custom/lua/augment_catalyst_drops.lua',
        'DROP_RATE',
        default=10,       # only used if the module file is missing
        cast=float,       # int (default) or float
    )
"""
from __future__ import annotations

import re
from functools import lru_cache
from pathlib import Path

_MISSING = object()

# Matches ONLY genuine module-level numeric constants, not table fields
# (`reward = 100` inside `{ ... }` is a table field, not a knob).
#   * `local X = N`      -- module-scoped, our idiomatic knob shape
#   * `X = N` at col 0   -- top-level global (rare but used for exports)
# Table fields are always indented under a `{`, so the col-0 requirement
# for globals filters them. Locals with any indent still match — Lua permits
# `local FOO = 1` inside a block, but almost every constant we care about
# is written at module top.
_LUA_ASSIGN_RE = re.compile(
    r"(?:^local\s+([A-Za-z_][A-Za-z0-9_]*)|^([A-Z][A-Z0-9_]*))"
    r"\s*=\s*(-?\d+(?:\.\d+)?)\b",
    re.MULTILINE,
)


@lru_cache(maxsize=128)
def _read(path_str: str) -> str:
    return Path(path_str).read_text(encoding="utf-8", errors="replace")


def lua_const(repo_root: Path, lua_rel: str, name: str, *,
              default=_MISSING, cast=int):
    """Read a runtime Lua numeric constant.

    repo_root: absolute repo root
    lua_rel:   repo-relative Lua path
    name:      Lua constant name (case-sensitive)
    default:   returned if file or name is missing; raises otherwise
    cast:      int (default) or float

    Raises FileNotFoundError if the Lua file is missing (and no default).
    Raises KeyError if the constant is missing from the file (and no default).
    """
    path = repo_root / lua_rel
    if not path.exists():
        if default is _MISSING:
            raise FileNotFoundError(
                f"[lua_const] {lua_rel} not found while resolving {name!r}. "
                "Pass default=... if this file is optional."
            )
        return default
    text = _read(str(path))
    # Prefer the LAST assignment to the name — Lua files often override
    # earlier defaults with tuning below (matches Lua semantics too).
    last = None
    for m in _LUA_ASSIGN_RE.finditer(text):
        n = m.group(1) or m.group(2)
        if n == name:
            last = m.group(3)
    if last is None:
        if default is _MISSING:
            raise KeyError(
                f"[lua_const] {name} not found in {lua_rel}. Add it to Lua "
                "as `local NAME = N`, or pass default=... if the miss is OK."
            )
        return default
    return cast(float(last)) if cast is int else cast(last)


def scan_lua_constants(repo_root: Path,
                       lua_glob: str = "modules/custom/lua/*.lua"
                       ) -> dict[str, list[tuple[str, float]]]:
    """Return {lua_filename: [(name, value_as_float), ...]} across the tree.

    Used by sync_audit's shadow-literal scanner to know which literals to
    flag as suspected drift.
    """
    out: dict[str, list[tuple[str, float]]] = {}
    for lua in sorted((repo_root).glob(lua_glob)):
        text = _read(str(lua))
        hits: list[tuple[str, float]] = []
        for m in _LUA_ASSIGN_RE.finditer(text):
            n = m.group(1) or m.group(2)
            hits.append((n, float(m.group(3))))
        if hits:
            out[lua.name] = hits
    return out
