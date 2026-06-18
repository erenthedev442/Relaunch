"""Generate the Accessories Vendor section inside docs/progression/gear-vendors.md.

Reads `modules/custom/lua/hunting_league_catalog.lua` and renders every
entry in `rewardCategories` EXCEPT the "Seals" category (which is owned
by the dedicated Seals NPC, not the Accessories NPC).

The Accessories NPC sits on the same row as the Armor + Weapons vendors
at Reisenjima Henge. Currency is **Hunt Marks** (NOT seals/medals), so
the cost column reads as raw mark counts.

Renders into a single DOCGEN marker block "accessories" — one H3 +
table per category, in catalog order. New categories added to the
catalog appear automatically; renames/reorders propagate without
touching the markdown.

The catalog is gitignored, so this generator runs against
`$LEGENDARY_LIVE_ROOT`. CI without that env var skips cleanly.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._bgwiki import urls_for_item


# Lua string literal in single OR double quotes; handles backslash escapes
# inside single-quoted strings (e.g. 'Epona\'s Ring').
_QUOTED = r"(?:'((?:[^'\\]|\\.)*)'|\"([^\"]*)\")"

_LABEL_RE = re.compile(r"\blabel\s*=\s*" + _QUOTED)
_NAME_RE  = re.compile(r"\bname\s*=\s*" + _QUOTED)
_COST_RE  = re.compile(r"\bcost\s*=\s*(\d+)")
_ID_RE    = re.compile(r"\bid\s*=\s*(\d+)")

# `currencyName = 'Hunt Marks'` from the catalog. Falls back to "Hunt Marks"
# so the rendering stays sensible if the field is removed.
_CURRENCY_RE = re.compile(r"\bcurrencyName\s*=\s*" + _QUOTED)

# `accessoriesPos = { x = N, y = N, z = N, rot = N }` — coords for the
# location row in the page intro table. Returns (x, y, z) floats or None.
_ACC_POS_RE = re.compile(
    r"accessoriesPos\s*=\s*\{[^}]*?"
    r"x\s*=\s*(-?[\d.]+)[^}]*?"
    r"y\s*=\s*(-?[\d.]+)[^}]*?"
    r"z\s*=\s*(-?[\d.]+)",
    re.DOTALL,
)


def _quoted_value(m: re.Match) -> str:
    raw = m.group(1) if m.group(1) is not None else m.group(2)
    return raw.replace("\\'", "'").replace('\\"', '"').replace("\\\\", "\\")


def _balanced_blocks(text: str):
    """Yield (start, end_exclusive) for each top-level {...} block.

    Handles nested braces, Lua `--` line comments, and both single- and
    double-quoted strings (with backslash escapes). Copied from
    hunting_league.py — keep the two in sync if either has to change."""
    depth = 0
    start = None
    i = 0
    n = len(text)
    while i < n:
        c = text[i]
        # Lua line comment: skip to end of line.
        if c == "-" and i + 1 < n and text[i + 1] == "-":
            nl = text.find("\n", i)
            if nl == -1:
                break
            i = nl + 1
            continue
        # Quoted string: skip until matching close quote, respecting escapes
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


def _extract_stats(item_body: str) -> list[str]:
    """Pull the stats array (list of short string literals) from one item
    body. The catalog format is:
        stats = { 'foo', 'bar', 'baz' }
    Returns [] if no stats key found."""
    m = re.search(r"\bstats\s*=\s*", item_body)
    if not m:
        return []
    remaining = item_body[m.end():]
    block = next(_balanced_blocks(remaining), None)
    if block is None:
        return []
    inner = remaining[block[0] + 1: block[1] - 1]
    # Pull every quoted string out, preserving order.
    stats: list[str] = []
    for sm in re.finditer(_QUOTED, inner):
        stats.append(_quoted_value(sm))
    return stats


def _extract_categories(text: str) -> list[dict]:
    """Parse `rewardCategories = { {label=..., items={...}}, ... }`.

    Returns a list of dicts in catalog order:
        [{'label': str, 'items': [{'name', 'id', 'cost', 'stats': [...]}]}]
    """
    m = re.search(r"\brewardCategories\s*=\s*", text)
    if not m:
        return []
    remaining = text[m.end():]
    outer = next(_balanced_blocks(remaining), None)
    if outer is None:
        return []
    outer_inner = remaining[outer[0] + 1: outer[1] - 1]

    categories: list[dict] = []
    for cs, ce in _balanced_blocks(outer_inner):
        cat_body = outer_inner[cs + 1: ce - 1]

        label_m = _LABEL_RE.search(cat_body)
        if not label_m:
            continue
        label = _quoted_value(label_m)

        items_m = re.search(r"\bitems\s*=\s*", cat_body)
        if not items_m:
            categories.append({"label": label, "items": []})
            continue
        items_remaining = cat_body[items_m.end():]
        items_outer = next(_balanced_blocks(items_remaining), None)
        if items_outer is None:
            categories.append({"label": label, "items": []})
            continue
        items_inner = items_remaining[items_outer[0] + 1: items_outer[1] - 1]

        items: list[dict] = []
        for is_, ie in _balanced_blocks(items_inner):
            ibody = items_inner[is_ + 1: ie - 1]
            nm = _NAME_RE.search(ibody)
            cm = _COST_RE.search(ibody)
            im = _ID_RE.search(ibody)
            if not (nm and cm):
                continue
            items.append({
                "name":  _quoted_value(nm),
                "id":    int(im.group(1)) if im else 0,
                "cost":  int(cm.group(1)),
                "stats": _extract_stats(ibody),
            })

        categories.append({"label": label, "items": items})
    return categories


def _escape_md(s: str) -> str:
    return s.replace("|", "\\|").replace("\n", " ")


def _item_link(name: str) -> str:
    """Item name as a BG-Wiki link with data-img tooltip. Mirrors the
    armor_npc.py / weapons_npc.py format so the page styling is uniform."""
    page_url, image_url = urls_for_item(name, None)
    return (
        f'<a class="item-link" href="{page_url}" '
        f'data-img="{image_url}" target="_blank" rel="noopener">'
        f'{_escape_md(name)}</a>'
    )


def _fmt_pos(pos: tuple[float, float, float] | None) -> str:
    if pos is None:
        return "_(position not configured)_"
    x, y, z = pos
    return f"`({x:g}, {y:g}, {z:g})`"


def _render_accessories(
    categories: list[dict],
    currency: str,
    accessories_pos: tuple[float, float, float] | None,
) -> str:
    """One DOCGEN marker block, every category in catalog order."""
    if not categories:
        return "_No accessory categories parsed from the catalog._"

    total_items = sum(len(c["items"]) for c in categories)
    pos_str = _fmt_pos(accessories_pos)

    lines: list[str] = [
        (
            "The **Hunt Accessories NPC** stands at " + pos_str +
            " on the same row as the Armor and Weapons vendors. Unlike those"
            " two, the Accessories vendor takes **" + currency + "** directly"
            " — no seal exchange step. Marks are earned by killing NMs via the"
            " [Hunting League](index.md) Spawner."
        ),
        "",
        f"_{total_items} items across {len(categories)} categories. "
        f"All costs are in {currency}._",
        "",
    ]

    for cat in categories:
        items = cat["items"]
        if not items:
            continue
        lines.append(f"### {cat['label']}")
        lines.append("")
        lines.append("| Item | Cost | Notes |")
        lines.append("|---|---:|---|")
        for it in items:
            stats_str = ", ".join(it["stats"]) if it["stats"] else ""
            lines.append(
                f"| {_item_link(it['name'])} | {it['cost']:,} | {_escape_md(stats_str)} |"
            )
        lines.append("")

    return "\n".join(lines).rstrip()


def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/hunting_league_catalog.lua")
    if src is None:
        print("[accessories_npc] skip: hunting_league_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")

    # Currency name + accessories position both come from the catalog so
    # renaming/moving the NPC in Lua propagates to the docs without manual
    # edits.
    cm = _CURRENCY_RE.search(text)
    currency = _quoted_value(cm) if cm else "Hunt Marks"

    pm = _ACC_POS_RE.search(text)
    accessories_pos: tuple[float, float, float] | None = None
    if pm:
        accessories_pos = (float(pm.group(1)), float(pm.group(2)), float(pm.group(3)))

    # Sanity signal: if the catalog has rewardCategories text but we extract
    # zero, a field name probably changed (label/items/cost). Raise instead
    # of silently emitting "_No accessory categories parsed_" — that would
    # be a regression masquerading as a successful run.
    categories = _extract_categories(text)
    if "rewardCategories" in text and not categories:
        raise RuntimeError(
            "hunting_league_catalog.lua has a rewardCategories block but "
            "_extract_categories returned zero entries. A required field "
            "(label/items/name/cost) was likely renamed — update the "
            "regex constants at the top of accessories_npc.py."
        )

    # Drop "Seals" — that category is owned by the Seals NPC, not the
    # Accessories NPC. Players reading the Accessories section don't need
    # the currency exchange listed twice on the same page.
    categories = [c for c in categories if c["label"] != "Seals"]

    page = docs_dir / "progression" / "gear-vendors.md"
    content = _render_accessories(categories, currency, accessories_pos)
    wrote = write_between_markers(page, "accessories", content)

    if not wrote:
        print(f"[accessories_npc] accessories: marker missing in {page.name} — add <!-- DOCGEN:BEGIN id=\"accessories\" --> / <!-- DOCGEN:END id=\"accessories\" --> block to render")
        return

    total_items = sum(len(c["items"]) for c in categories)
    print(
        f"[accessories_npc] accessories: {len(categories)} categories, "
        f"{total_items} items written into marker"
    )
