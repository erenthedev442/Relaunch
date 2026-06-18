"""Substitute live setting values into narrative markdown.

Lets you write `{{setting:EXP_RATE}}×` in any docs/**/*.md file and have
it expanded to the current value from `settings/main.lua` (or `map.lua`)
on every refresh.

First run rewrites each `{{setting:NAME}}` token as a self-contained
HTML-comment marker so the binding survives subsequent regenerations:

    Source:   With {{setting:EXP_RATE}}× rates, an afternoon.
    After 1st run:
              With <!--setting:EXP_RATE-->3<!--/setting-->× rates, an afternoon.
    After value changes from 3 → 5:
              With <!--setting:EXP_RATE-->5<!--/setting-->× rates, an afternoon.

HTML comments render as nothing in MkDocs Material, so the page reads
identically to what you'd write by hand — just kept in sync.

Syntax forms:
  {{setting:NAME}}              # prefer main.lua, fall back to map.lua
  {{setting:main.NAME}}         # force main.lua
  {{setting:map.NAME}}          # force map.lua
  {{setting:NAME:int}}          # drop decimals (e.g. 10.0 -> "10")
  {{setting:NAME:pct}}          # multiply by 100, append % (0.8 -> "80%")
  {{setting:NAME:comma}}        # thousands separator (100000 -> "100,000")

Unknown setting names are left unchanged and reported as a WARN. Tokens
inside marker blocks owned by other generators (e.g. rates-at-a-glance)
are processed normally — order in generate.py puts this generator AFTER
those so substituted values land in their final form.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source


# --- token + marker patterns -------------------------------------------------
_TOKEN_RE = re.compile(
    r"\{\{\s*setting\s*:\s*"
    r"(?:(main|map)\.)?"        # optional file qualifier
    r"([A-Z][A-Z0-9_]*)\s*"     # setting name
    r"(?::\s*([a-z_]+))?\s*"    # optional format spec
    r"\}\}"
)

_MARKER_RE = re.compile(
    r"<!--setting:"
    r"(?:(main|map)\.)?"
    r"([A-Z][A-Z0-9_]*)"
    r"(?::([a-z_]+))?"
    r"-->"
    r".*?"
    r"<!--/setting-->",
    re.DOTALL,
)

# --- settings parser (kept local so this module has no cross-deps) -----------
_SETTING_LINE = re.compile(r"^\s*([A-Z][A-Z0-9_]+)\s*=\s*(.+)$")


def _split_value_comment(rest: str) -> tuple[str, str]:
    in_s = in_d = False
    i = 0
    while i < len(rest) - 1:
        c = rest[i]
        if c == "'" and not in_d:
            in_s = not in_s
        elif c == '"' and not in_s:
            in_d = not in_d
        elif rest[i:i + 2] == "--" and not in_s and not in_d:
            return rest[:i], rest[i + 2:]
        i += 1
    return rest, ""


def _parse_settings(text: str) -> dict[str, str]:
    out: dict[str, str] = {}
    for raw in text.splitlines():
        m = _SETTING_LINE.match(raw.rstrip())
        if not m:
            continue
        name, rest = m.group(1), m.group(2)
        value, _ = _split_value_comment(rest)
        # Strip whitespace AND trailing comma in either order — the lua line
        # `EXP_RATE = 10.000, -- comment` becomes "10.000, " here, so we need
        # both stripped regardless of which comes last.
        value = value.strip().rstrip(",").strip()
        if not value or value.endswith(".."):
            continue
        if value.startswith("{") and not value.endswith("}"):
            continue
        # Strip outer quotes from string settings
        if len(value) >= 2 and value[0] in "'\"" and value[-1] == value[0]:
            value = value[1:-1]
        out[name] = value
    return out


# --- formatting -------------------------------------------------------------
def _format(raw: str, fmt: str | None) -> str:
    fmt = fmt or "auto"
    if fmt == "raw":
        return raw
    try:
        if "." in raw:
            n = float(raw)
        else:
            n = int(raw)
    except ValueError:
        return raw

    if fmt == "int":
        return str(int(n))
    if fmt == "pct":
        return f"{n * 100:g}%"
    if fmt == "comma":
        return f"{int(n):,}" if n == int(n) else f"{n:,}"
    # auto: integer-looking floats become ints, fractions keep needed precision
    if isinstance(n, float) and n == int(n):
        return str(int(n))
    if isinstance(n, float):
        return f"{n:g}"
    return str(n)


# --- main -------------------------------------------------------------------
def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "settings")
    if src is None:
        print("[settings_inject] skip: settings/ not found")
        return

    main_settings: dict[str, str] = {}
    map_settings: dict[str, str] = {}
    if (src / "main.lua").exists():
        main_settings = _parse_settings((src / "main.lua").read_text(encoding="utf-8"))
    if (src / "map.lua").exists():
        map_settings = _parse_settings((src / "map.lua").read_text(encoding="utf-8"))

    if not main_settings and not map_settings:
        print("[settings_inject] skip: no settings parsed")
        return

    def lookup(qualifier: str | None, name: str) -> str | None:
        if qualifier == "main":
            return main_settings.get(name)
        if qualifier == "map":
            return map_settings.get(name)
        # Unqualified: prefer main, then map
        if name in main_settings:
            return main_settings[name]
        return map_settings.get(name)

    files_changed = 0
    expansions = 0       # {{...}} → marker form (first time)
    refreshes  = 0       # marker form → marker form (value possibly updated)
    missing: set[str] = set()

    for md in sorted(docs_dir.rglob("*.md")):
        text = md.read_text(encoding="utf-8")
        original = text

        # Pass 1: expand any bare {{setting:X}} tokens into marker form
        def expand(m: re.Match) -> str:
            nonlocal expansions
            qual, name, fmt = m.group(1), m.group(2), m.group(3)
            val = lookup(qual, name)
            if val is None:
                missing.add(f"{qual + '.' if qual else ''}{name}")
                return m.group(0)
            expansions += 1
            qual_str = f"{qual}." if qual else ""
            fmt_str = f":{fmt}" if fmt else ""
            return f"<!--setting:{qual_str}{name}{fmt_str}-->{_format(val, fmt)}<!--/setting-->"

        text = _TOKEN_RE.sub(expand, text)

        # Pass 2: refresh existing markers (value may have drifted since last run)
        def refresh(m: re.Match) -> str:
            nonlocal refreshes
            qual, name, fmt = m.group(1), m.group(2), m.group(3)
            val = lookup(qual, name)
            if val is None:
                missing.add(f"{qual + '.' if qual else ''}{name}")
                return m.group(0)
            refreshes += 1
            qual_str = f"{qual}." if qual else ""
            fmt_str = f":{fmt}" if fmt else ""
            return f"<!--setting:{qual_str}{name}{fmt_str}-->{_format(val, fmt)}<!--/setting-->"

        text = _MARKER_RE.sub(refresh, text)

        if text != original:
            md.write_text(text, encoding="utf-8")
            files_changed += 1

    print(f"[settings_inject] {expansions} new + {refreshes} refreshed tokens "
          f"across {files_changed} file(s)")
    if missing:
        print(f"[settings_inject] WARN unknown settings: {sorted(missing)}")
