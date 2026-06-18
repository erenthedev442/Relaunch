"""Sync docs/endgame/seasonal-events.md with seasonal_events_catalog.lua.

A seasonal event is a UTC window during which Hunting League kills earn a bonus
mark multiplier. The catalog ships with its event list *empty* (only
commented-out examples), so this generator must render a friendly empty-state
line when nothing is scheduled, and a table when one or more real events exist.

Commented-out example entries (`-- { ... }`) are NOT counted — only live,
uncommented entries become rows.

Markers written:
  seasonal-events-schedule  — the events table, or the empty-state line
"""
from __future__ import annotations

import re
from datetime import datetime, timezone
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._luaparse import section


_EMPTY_LINE = ("_No seasonal event is running right now — check back around "
               "holidays!_")


def _strip_line_comments(text: str) -> str:
    """Drop Lua line comments so commented-out example entries don't parse.

    Walks the text honouring single/double-quoted strings so a `--` inside a
    string literal is left intact; everything from an out-of-string `--` to the
    end of that line is removed.
    """
    out = []
    i, n = 0, len(text)
    in_s = in_d = False
    while i < n:
        c = text[i]
        if not in_s and not in_d and c == "-" and i + 1 < n and text[i + 1] == "-":
            nl = text.find("\n", i)
            if nl == -1:
                break
            i = nl  # keep the newline itself
            continue
        if c == "'" and not in_d:
            in_s = not in_s
        elif c == '"' and not in_s:
            in_d = not in_d
        out.append(c)
        i += 1
    return "".join(out)


def _parse_events(text: str) -> list[dict]:
    """Return live events as ordered dicts: {name, multiplier, start, finish, priority}."""
    block = section(text, "catalog.events")
    if not block:
        return []
    live = _strip_line_comments(block)

    events: list[dict] = []
    for entry in re.findall(r"\{[^{}]*\}", live):
        name_m = re.search(r"name\s*=\s*'([^']+)'", entry)
        mult_m = re.search(r"multiplier\s*=\s*([0-9.]+)", entry)
        if not (name_m and mult_m):
            continue
        start_m = re.search(r"start\s*=\s*(\d+)", entry)
        fin_m   = re.search(r"finish\s*=\s*(\d+)", entry)
        prio_m  = re.search(r"priority\s*=\s*(\d+)", entry)
        events.append({
            "name":       name_m.group(1),
            "multiplier": float(mult_m.group(1)),
            "start":      int(start_m.group(1)) if start_m else None,
            "finish":     int(fin_m.group(1)) if fin_m else None,
            "priority":   int(prio_m.group(1)) if prio_m else 0,
        })
    return events


def _fmt_ts(ts) -> str:
    if ts is None:
        return "—"
    return datetime.fromtimestamp(ts, tz=timezone.utc).strftime("%b %d, %Y %H:%M UTC")


def _fmt_mult(v: float) -> str:
    return f"{v:g}×"


def _render(events: list[dict]) -> str:
    if not events:
        return _EMPTY_LINE

    # Show the highest-priority windows first, then earliest start.
    ordered = sorted(events, key=lambda e: (-e["priority"], e["start"] or 0))
    rows = [
        "| Event | Mark bonus | Starts | Ends |",
        "|---|---:|---|---|",
    ]
    for e in ordered:
        rows.append(
            f"| **{e['name']}** | {_fmt_mult(e['multiplier'])} "
            f"| {_fmt_ts(e['start'])} | {_fmt_ts(e['finish'])} |"
        )
    return "\n".join(rows)


# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/seasonal_events_catalog.lua")
    if src is None:
        print("[seasonal_events] skip: seasonal_events_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    events = _parse_events(text)

    page = docs_dir / "endgame" / "seasonal-events.md"
    wrote = write_between_markers(page, "seasonal-events-schedule", _render(events))
    written = 1 if wrote else 0
    state = f"{len(events)} event(s)" if events else "empty-state"
    print(f"[seasonal_events] {written}/1 marker block(s) written ({state})")
