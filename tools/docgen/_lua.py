"""Shared Lua-table parsing primitives for docgen + the catalog exporter.

The custom catalogs under `modules/custom/lua/` are plain data tables —
`return { ... }` or `local X = { ... }` — and the fields we extract are
string / number / boolean literals. Rather than embed a Lua runtime we
brace-scan the small, stable subset we need and pull fields with targeted
regexes.

This is the CANONICAL home for the brace-balanced scanner that started life
inside `generators/hunting_league.py`. New code should import from here
instead of copying it, so the parser itself never drifts.

Not handled (none appear in the catalogs): Lua long comments `--[[ ]]`
and long strings `[[ ]]`. Field regexes do not strip line comments, so a
commented-out `key = 'value'` inside a block could be picked up — the live
catalogs don't do that, matching the long-proven hunting_league approach.
"""
from __future__ import annotations

import re

# A Lua string literal in single OR double quotes, honoring backslash escapes
# (e.g. 'Epona\'s Ring'). Two capture groups: 1 = single-quoted body, 2 =
# double-quoted body.
QUOTED = r"(?:'((?:[^'\\]|\\.)*)'|\"((?:[^\"\\]|\\.)*)\")"


def unquote(m: re.Match) -> str:
    """Decode a QUOTED match (either quote style) into a plain string."""
    raw = m.group(1) if m.group(1) is not None else m.group(2)
    if raw is None:
        return ""
    return raw.replace("\\'", "'").replace('\\"', '"').replace("\\\\", "\\")


def iter_blocks(text: str):
    """Yield (start, end_exclusive) for each top-level ``{...}`` block in text.

    Tracks brace depth while skipping Lua `--` line comments and single/double
    quoted strings (with backslash escapes), so braces inside comments or
    strings don't throw off the count.
    """
    depth = 0
    start = None
    i = 0
    n = len(text)
    while i < n:
        c = text[i]
        # Lua line comment -> skip to end of line.
        if c == "-" and i + 1 < n and text[i + 1] == "-":
            nl = text.find("\n", i)
            if nl == -1:
                break
            i = nl + 1
            continue
        # Quoted string -> skip to matching close quote, honoring escapes.
        if c == "'" or c == '"':
            quote = c
            i += 1
            while i < n:
                cc = text[i]
                if cc == "\\" and i + 1 < n:
                    i += 2
                    continue
                if cc == quote:
                    i += 1
                    break
                i += 1
            continue
        if c == "{":
            if depth == 0:
                start = i
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0 and start is not None:
                yield (start, i + 1)
                start = None
        i += 1


def table_body(text: str, name: str) -> str | None:
    """Return the inner text (no outer braces) of the first ``name = { ... }``
    table, or None. `name` may contain dots (e.g. ``catalog.guilds``) and is
    matched literally, guarded so a longer identifier can't match by accident.
    """
    m = re.search(r"(?<![\w.])" + re.escape(name) + r"\s*=\s*", text)
    if not m:
        return None
    remaining = text[m.end():]
    blk = next(iter_blocks(remaining), None)
    if blk is None:
        return None
    return remaining[blk[0] + 1: blk[1] - 1]


def entry_blocks(body: str):
    """Yield the inner text of each top-level ``{...}`` entry within a table
    body. Works for array-style and map-style tables alike (keys ignored)."""
    for s, e in iter_blocks(body):
        yield body[s + 1: e - 1]


def map_entries(body: str):
    """Yield ``(key, inner_text)`` for each top-level entry in a table body.

    For map-style tables (``key = { ... }``) `key` is the bare Lua identifier;
    for array-style entries (``{ ... }``) `key` is None. Lets one code path
    handle both shapes.
    """
    for s, e in iter_blocks(body):
        km = re.search(r"([A-Za-z_]\w*)\s*=\s*$", body[:s])
        yield (km.group(1) if km else None), body[s + 1: e - 1]


def field_str(body: str, key: str) -> str | None:
    """First ``key = '...'`` string field in body, decoded, or None."""
    m = re.search(r"\b" + re.escape(key) + r"\s*=\s*" + QUOTED, body)
    return unquote(m) if m else None


def field_num(body: str, key: str):
    """First ``key = <number>`` field as int (no dot) or float (with dot)."""
    m = re.search(r"\b" + re.escape(key) + r"\s*=\s*(-?\d+(?:\.\d+)?)", body)
    if not m:
        return None
    s = m.group(1)
    return float(s) if "." in s else int(s)


def field_bool(body: str, key: str):
    """First ``key = true|false`` field as a bool, or None if absent."""
    m = re.search(r"\b" + re.escape(key) + r"\s*=\s*(true|false)\b", body)
    if not m:
        return None
    return m.group(1) == "true"


def field_str_list(body: str, key: str) -> list[str]:
    """All quoted strings inside a ``key = { '...', '...' }`` sub-table.
    Returns [] if the key/sub-table is absent."""
    sub = table_body(body, key)
    if sub is None:
        return []
    return [unquote(m) for m in re.finditer(QUOTED, sub)]
