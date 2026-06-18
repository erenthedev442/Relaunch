"""Generate settings-diff tables inside docs/changes/index.md.

Compares `settings/main.lua` and `settings/map.lua` against the upstream
defaults in `settings/default/`. Writes the result into marker blocks so
hand-written narrative on the page is preserved.

Marker IDs:
  - "settings-main" — diff of settings/main.lua
  - "settings-map"  — diff of settings/map.lua

Only top-level scalar settings (numbers, booleans, single-line strings)
are diffed. Multi-line tables and concatenated strings are skipped.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers


_SETTING_LINE = re.compile(r"^\s*([A-Z][A-Z0-9_]+)\s*=\s*(.+)$")


def generate(repo_root: Path, docs_dir: Path) -> None:
    settings_root = resolve_source(repo_root, "settings")
    if settings_root is None:
        print("[settings_changes] skip: settings/ not found")
        return

    default_dir = settings_root / "default"
    if not default_dir.exists():
        print(f"[settings_changes] skip: {default_dir} not found")
        return

    page = docs_dir / "changes" / "index.md"

    total_written = 0
    for fn in ("main.lua", "map.lua"):
        cur = settings_root / fn
        dft = default_dir / fn
        if not (cur.exists() and dft.exists()):
            print(f"[settings_changes] skip {fn}: file missing")
            continue
        diffs = _diff(dft.read_text(encoding="utf-8", errors="replace"),
                      cur.read_text(encoding="utf-8", errors="replace"))
        marker_id = f"settings-{fn.replace('.lua', '')}"
        content = _render_table(fn, diffs)
        wrote = write_between_markers(page, marker_id, content)
        if wrote:
            print(f"[settings_changes] {marker_id}: {len(diffs)} diffs written into markers")
            total_written += 1
        else:
            print(f"[settings_changes] {marker_id}: skipped (markers not found in {page.name})")

    if total_written == 0:
        print(f"[settings_changes] no marker blocks updated; add DOCGEN markers to {page} to enable")


def _parse(text: str) -> dict[str, tuple[str, str]]:
    """Return {name: (value, comment)} for top-level scalar settings."""
    result: dict[str, tuple[str, str]] = {}
    for raw in text.splitlines():
        m = _SETTING_LINE.match(raw.rstrip())
        if not m:
            continue
        name, rest = m.group(1), m.group(2)
        value, comment = _split_value_comment(rest)
        value = value.rstrip(",").strip()
        if not value:
            continue
        # Skip complex values
        if value.startswith("{") and not value.endswith("}"):
            continue
        if value.endswith(".."):
            continue
        if value.startswith("function"):
            continue
        result[name] = (value, comment.strip())
    return result


def _split_value_comment(rest: str) -> tuple[str, str]:
    in_single = in_double = False
    i = 0
    while i < len(rest) - 1:
        c = rest[i]
        if c == "'" and not in_double:
            in_single = not in_single
        elif c == '"' and not in_single:
            in_double = not in_double
        elif rest[i:i + 2] == "--" and not in_single and not in_double:
            return rest[:i], rest[i + 2:]
        i += 1
    return rest, ""


def _diff(default_text: str, current_text: str) -> list[dict]:
    defaults = _parse(default_text)
    current = _parse(current_text)
    diffs = []
    for name, (cur_val, cur_comment) in current.items():
        if name not in defaults:
            continue
        def_val, _ = defaults[name]
        if _normalize(def_val) != _normalize(cur_val):
            diffs.append({
                "name": name,
                "default": def_val,
                "current": cur_val,
                "comment": cur_comment,
            })
    return sorted(diffs, key=lambda d: d["name"])


def _normalize(v: str) -> str:
    """Treat 'foo' and \"foo\" as equal, and 1.0 == 1.000."""
    s = v.strip()
    if s.startswith("'") and s.endswith("'"):
        return s[1:-1]
    if s.startswith('"') and s.endswith('"'):
        return s[1:-1]
    # Numbers: collapse trailing zeros after a decimal point
    try:
        if "." in s:
            return f"{float(s):g}"
        return str(int(s))
    except ValueError:
        return s


def _escape_md(s: str) -> str:
    return s.replace("|", "\\|").replace("\n", " ")


def _render_table(filename: str, diffs: list[dict]) -> str:
    if not diffs:
        return f"_No customizations in `settings/{filename}` — all values match upstream defaults._"
    lines = [
        f"_{len(diffs)} settings differ from upstream defaults in `settings/{filename}`._",
        "",
        "| Setting | Upstream default | This server | Comment |",
        "|---|---|---|---|",
    ]
    for d in diffs:
        lines.append(
            f"| `{d['name']}` "
            f"| `{_escape_md(d['default'])}` "
            f"| `{_escape_md(d['current'])}` "
            f"| {_escape_md(d['comment'])} |"
        )
    return "\n".join(lines)
