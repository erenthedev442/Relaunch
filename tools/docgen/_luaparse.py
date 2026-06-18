"""Shared helpers for the custom-system docgen generators.

Every custom system stores its config in `modules/custom/lua/*_catalog.lua`
as `local catalog = {}` followed by `catalog.<name> = { ... }` blocks. These
helpers slice a named block out of the Lua source — brace-balanced and aware of
line comments and quoted strings — so each generator's per-field regexes can't
accidentally match across unrelated sections.

Usage:
    from tools.docgen._luaparse import section, ints, commafy
    block = section(text, "catalog.slots")     # the whole `catalog.slots = {...}`
    reel  = section(block, "reel")             # a nested table inside it
    sizes = ints("{ 5000, 25000 }")            # -> [5000, 25000]
"""
from __future__ import annotations

import re


def section(text: str, anchor: str) -> str:
    """Return the `<anchor> = { ... }` block (outer braces included), or ''.

    `anchor` is matched literally (e.g. "catalog.slots" or a nested "reel").
    Lua line comments (`-- ...`) and single/double-quoted strings are skipped
    so braces or apostrophes inside them never throw off the brace counter.
    Block comments (`--[[ ]]`) aren't handled — the catalogs don't use them.
    """
    m = re.search(rf"{re.escape(anchor)}\s*=\s*\{{", text)
    if not m:
        return ""
    start = m.end() - 1   # the opening brace
    i, n, depth = start, len(text), 0
    while i < n:
        c = text[i]
        if c == "-" and i + 1 < n and text[i + 1] == "-":   # line comment
            nl = text.find("\n", i)
            if nl == -1:
                return ""
            i = nl + 1
            continue
        if c == "'" or c == '"':                             # quoted string
            q = c
            i += 1
            while i < n:
                if text[i] == "\\" and i + 1 < n:
                    i += 2
                    continue
                if text[i] == q:
                    i += 1
                    break
                i += 1
            continue
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return text[start:i + 1]
        i += 1
    return ""


def ints(s: str) -> list[int]:
    """Every integer literal in `s`, in order (handles negatives)."""
    return [int(x) for x in re.findall(r"-?\d+", s)]


def commafy(n) -> str:
    """12345 -> '12,345' (rounds floats to int first)."""
    return f"{int(round(float(n))):,}"
