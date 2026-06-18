"""Generate the Crafting Exchange table inside docs/progression/gm-home.md.

Reads: modules/custom/lua/crafting_exchange_catalog.lua

Marker ID:
  - "gm-home-crafting-exchange" -- full exchange table (Item / Craft /
    Hunt Marks / Daily Cap) plus an "N items across M crafts" summary line.

The catalog lives under modules/custom/ which is gitignored, so this
generator normally runs against $LEGENDARY_LIVE_ROOT. CI without that env
var skips cleanly (resolve_source returns None).
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers

# ---------------------------------------------------------------------------
# Lua helpers (duplicated per the established pattern — see daily_board.py)
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

def _parse_exchanges(text: str) -> list[dict]:
    """Parse catalog.exchanges into ordered dicts (source order preserved).

    Each entry: { name, skill, marks, maxPerDay }. Entries missing a name,
    skill, or marks reward are skipped. `maxPerDay` is None when uncapped.
    """
    m = re.search(r'\bexchanges\s*=\s*\{', text)
    if not m:
        return []
    for start, end in _balanced_blocks(text[m.start():]):
        outer_block = text[m.start():][start:end]
        break
    else:
        return []

    exchanges: list[dict] = []
    # Iterate entry sub-tables inside the outer array (skip the leading '{').
    inner = outer_block[1:]
    for es, ee in _balanced_blocks(inner):
        entry = inner[es:ee]

        name_m  = re.search(r'\bname\s*=\s*(' + _QUOTED + r')', entry)
        skill_m = re.search(r'\bskill\s*=\s*(' + _QUOTED + r')', entry)

        # marks live inside a nested `reward = { marks = N, ... }` block.
        reward_m = re.search(r'\breward\s*=\s*\{([^}]*)\}', entry)
        marks_m = None
        if reward_m:
            marks_m = re.search(r'\bmarks\s*=\s*(\d+)', reward_m.group(1))

        if not (name_m and skill_m and marks_m):
            continue

        cap_m = re.search(r'\bmaxPerDay\s*=\s*(\d+)', entry)

        exchanges.append({
            "name":      _quoted_value(name_m.group(1).strip()),
            "skill":     _quoted_value(skill_m.group(1).strip()),
            "marks":     int(marks_m.group(1)),
            "maxPerDay": int(cap_m.group(1)) if cap_m else None,
        })

    return exchanges


# ---------------------------------------------------------------------------
# Renderer
# ---------------------------------------------------------------------------

def _escape_md(s: str) -> str:
    return s.replace("|", "\\|").replace("\n", " ")


def _render(exchanges: list[dict]) -> str:
    if not exchanges:
        return "_No exchange data parsed from the catalog._"

    # Distinct crafts in first-seen order, for the summary line.
    crafts: list[str] = []
    for e in exchanges:
        if e["skill"] not in crafts:
            crafts.append(e["skill"])

    n_items = len(exchanges)
    n_crafts = len(crafts)
    item_word = "item" if n_items == 1 else "items"
    craft_word = "craft" if n_crafts == 1 else "crafts"

    lines = [
        f"_The full exchange list: **{n_items} {item_word}** across "
        f"**{n_crafts} {craft_word}**._",
        "",
        "| Item | Craft | Hunt Marks | Daily Cap |",
        "|---|---|---:|---:|",
    ]
    for e in exchanges:
        cap = str(e["maxPerDay"]) if e["maxPerDay"] is not None else "—"
        lines.append(
            f"| {_escape_md(e['name'])} | {_escape_md(e['skill'])} "
            f"| {e['marks']} | {cap} |"
        )

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/crafting_exchange_catalog.lua")
    if src is None:
        print("[crafting_exchange] skip: crafting_exchange_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")

    page = docs_dir / "progression" / "gm-home.md"
    if not page.exists():
        print(f"[crafting_exchange] skip: target page {page} not found")
        return

    exchanges = _parse_exchanges(text)

    # Sanity guard: if the catalog clearly has exchange entries (every one
    # carries a `marks = N` reward) but we parsed zero, a field name probably
    # changed. Raise so the section keeps its existing published content
    # instead of regressing to the "_No exchange data_" placeholder.
    marks_signals = len(re.findall(r'\bmarks\s*=\s*\d+', text))
    if marks_signals > 0 and not exchanges:
        raise RuntimeError(
            f"crafting_exchange_catalog.lua has {marks_signals} `marks = N` "
            f"signals but _parse_exchanges returned zero entries. A required "
            f"field (name/skill/reward.marks) was probably renamed -- update "
            f"_parse_exchanges in this generator."
        )

    content = _render(exchanges)
    wrote = write_between_markers(page, "gm-home-crafting-exchange", content)
    if wrote:
        n_crafts = len({e["skill"] for e in exchanges})
        print(
            f"[crafting_exchange] {len(exchanges)} items across {n_crafts} "
            f"crafts written into marker"
        )
    else:
        print(
            f"[crafting_exchange] marker 'gm-home-crafting-exchange' not found "
            f"in {page.name}"
        )
