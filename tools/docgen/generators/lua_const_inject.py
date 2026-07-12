"""Substitute named Lua constants into narrative markdown.

Mirrors settings_inject, but for module constants: write
`{{lua:death_penalty.lua:PENALTY}}` in any docs/**/*.md and it expands to the
current value parsed from `modules/custom/lua/death_penalty.lua`, then stays
in sync on every refresh. This is what lets hand prose state a tuned price or
cost ("costs **10,000 gil** flat") without becoming a drift liability — the
number is re-read from the same Lua the server runs.

First run rewrites each token as a self-contained HTML-comment marker so the
binding survives regenerations:

    Source:   costs **{{lua:Augment_Moogle.lua:GIL_COST:comma}} gil** flat
    Built:    costs **<!--luaconst:Augment_Moogle.lua:GIL_COST:comma-->10,000<!--/luaconst--> gil** flat

Syntax:
  {{lua:<file>:<NAME>}}         # <file> is relative to modules/custom/lua/,
                                # or a full repo-relative path with slashes
  {{lua:<file>:<NAME>:int}}     # drop decimals
  {{lua:<file>:<NAME>:comma}}   # thousands separator

Value resolution tries, in order:
  local NAME = <number>
  <anything>.NAME = <number>    (catalog.NAME / C.NAME / cfg.NAME ...)
  NAME = <number>

Unknown files/names are left unchanged and reported as WARN so a renamed
constant can't silently freeze a page value.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source

_TOKEN_RE = re.compile(
    r"\{\{\s*lua\s*:\s*([\w./-]+\.lua)\s*:\s*([A-Za-z_][\w]*)\s*(?::\s*([a-z_]+))?\s*\}\}"
)
_MARKER_RE = re.compile(
    r"<!--luaconst:([\w./-]+\.lua):([A-Za-z_][\w]*)(?::([a-z_]+))?-->.*?<!--/luaconst-->",
    re.DOTALL,
)


def _format(raw: str, fmt: str | None) -> str:
    try:
        n = float(raw) if "." in raw else int(raw)
    except ValueError:
        return raw
    if fmt == "int":
        return str(int(n))
    if fmt == "comma":
        return f"{int(n):,}" if n == int(n) else f"{n:,}"
    if isinstance(n, float) and n == int(n):
        return str(int(n))
    return f"{n:g}" if isinstance(n, float) else str(n)


def _lookup(text: str, name: str) -> str | None:
    esc = re.escape(name)
    for pat in (
        rf"\blocal\s+{esc}\s*=\s*(-?[\d.]+)",
        rf"[\w\]]\.{esc}\s*=\s*(-?[\d.]+)",
        rf"^\s*{esc}\s*=\s*(-?[\d.]+)",
    ):
        m = re.search(pat, text, re.MULTILINE)
        if m:
            return m.group(1)
    return None


def generate(repo_root: Path, docs_dir: Path) -> None:
    lua_root = resolve_source(repo_root, "modules")
    file_cache: dict[str, str | None] = {}

    def read_lua(fname: str) -> str | None:
        if fname not in file_cache:
            if "/" in fname or "\\" in fname:
                p = resolve_source(repo_root, fname)
            else:
                p = (lua_root / "custom" / "lua" / fname) if lua_root else None
                if p is not None and not p.exists():
                    p = None
            file_cache[fname] = p.read_text(encoding="utf-8", errors="replace") if p else None
        return file_cache[fname]

    missing: set[str] = set()
    files_changed = 0
    expansions = 0

    def resolve(fname: str, name: str, fmt: str | None) -> str | None:
        text = read_lua(fname)
        if text is None:
            missing.add(f"{fname} (file not found)")
            return None
        raw = _lookup(text, name)
        if raw is None:
            missing.add(f"{fname}:{name} (constant not found)")
            return None
        return _format(raw, fmt)

    for page in sorted(docs_dir.rglob("*.md")):
        try:
            text = page.read_text(encoding="utf-8")
        except OSError:
            continue
        orig = text

        def expand_token(m: re.Match) -> str:
            val = resolve(m.group(1), m.group(2), m.group(3))
            if val is None:
                return m.group(0)
            fmt = f":{m.group(3)}" if m.group(3) else ""
            return f"<!--luaconst:{m.group(1)}:{m.group(2)}{fmt}-->{val}<!--/luaconst-->"

        def refresh_marker(m: re.Match) -> str:
            val = resolve(m.group(1), m.group(2), m.group(3))
            if val is None:
                return m.group(0)
            fmt = f":{m.group(3)}" if m.group(3) else ""
            return f"<!--luaconst:{m.group(1)}:{m.group(2)}{fmt}-->{val}<!--/luaconst-->"

        text = _TOKEN_RE.sub(expand_token, text)
        text = _MARKER_RE.sub(refresh_marker, text)
        if text != orig:
            page.write_text(text, encoding="utf-8")
            files_changed += 1
            expansions += len(_TOKEN_RE.findall(orig)) + len(_MARKER_RE.findall(orig))

    if missing:
        print("[lua_const_inject] WARN — unresolved constants (tokens left as-is):")
        for m in sorted(missing):
            print(f"  - {m}")
    print(f"[lua_const_inject] {files_changed} page(s) updated, {expansions} binding(s) processed")
