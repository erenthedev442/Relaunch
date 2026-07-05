"""Generate Weapons NPC tables inside docs/progression/gear-vendors.md.

Reads `modules/custom/lua/gear_progression_catalog.lua` and writes one
marker block per tier (bronze/silver/gold). Each tier renders one table
per weapon category that contains at least one weapon. Empty categories
are omitted.

Marker IDs:
  - "weapons-bronze"
  - "weapons-silver"
  - "weapons-gold"

The catalog is normally gitignored, so this generator runs against
`$LEGENDARY_LIVE_ROOT`. CI without that env var skips cleanly.
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._bgwiki import urls_for_item
from tools.docgen.generators._vendor_common import tier_pill, tier_legend, tier_summary


_QUOTED = r"(?:'((?:[^'\\]|\\.)*)'|\"([^\"]*)\")"
_NAME_RE = re.compile(r"\bname\s*=\s*" + _QUOTED)
_COST_RE = re.compile(r"\bcost\s*=\s*(\d+)")
_JOBS_RE = re.compile(r"\bjobs\s*=\s*" + _QUOTED)
_WIKI_RE = re.compile(r"\bwiki\s*=\s*" + _QUOTED)

# Matches:  local swords = cat(catalog.bronze.weapons, 'Swords')
_CAT_BIND_RE = re.compile(
    r"local\s+(\w+)\s*=\s*cat\(\s*catalog\.(\w+)\.weapons\s*,\s*" + _QUOTED + r"\s*\)"
)
# Matches:  table.insert(swords, { id = ..., name = '...', cost = N, jobs = '...' })
_INSERT_RE = re.compile(
    r"table\.insert\(\s*(\w+)\s*,\s*\{(.*?)\}\s*\)",
    re.DOTALL,
)

_TIER_ORDER = ("bronze", "silver", "gold")

# Fallback if the catalog doesn't expose a seals table.
_FALLBACK_CURRENCY = {
    "bronze": "Beastmen's Seal",
    "silver": "Kindred's Seal",
    "gold":   "Abdhaljs Seal",
}

# Parse `catalog.seals = { bronze = { id = N, name = "X" }, ... }` from the
# Lua catalog source so renaming Bronze/Silver/Gold currencies in
# gear_progression_catalog.lua propagates here automatically.
_SEAL_TIER_RE = re.compile(
    r"(bronze|silver|gold)\s*=\s*\{[^}]*?name\s*=\s*['\"]([^'\"]+)['\"]",
)

def _parse_tier_currency(catalog_text: str) -> dict:
    found = {}
    for m in _SEAL_TIER_RE.finditer(catalog_text):
        found[m.group(1)] = m.group(2)
    return found
# Display order for weapon categories on the page. Mirrors the order in
# emptyCategories() in gear_progression_catalog.lua.
_CATEGORY_ORDER = (
    "Swords", "Daggers", "Clubs", "Staves",
    "Great Swords", "Axes", "Great Axes", "Scythes",
    "Polearms", "Katana", "Great Katana",
    "Archery", "Marksmanship", "Hand-to-Hand",
)

# Short per-tier descriptions shown in the legend under the Weapons heading.
_WEAPONS_TIER_DESC = {
    "bronze": "entry endgame ilvl 119",
    "silver": "event / Dynamis-D / Omen / Escha",
    "gold":   "REMA + Aeonic",
}


def _quoted_value(m: re.Match) -> str:
    raw = m.group(1) if m.group(1) is not None else m.group(2)
    return raw.replace("\\'", "'").replace('\\"', '"').replace("\\\\", "\\")


def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/gear_progression_catalog.lua")
    if src is None:
        print("[weapons_npc] skip: gear_progression_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")

    # Pull seal/currency names from the catalog so renames propagate here.
    parsed_currency = _parse_tier_currency(text)
    tier_currency = {
        t: parsed_currency.get(t, _FALLBACK_CURRENCY[t]) for t in _TIER_ORDER
    }
    print(f"[weapons_npc] tier currencies: {tier_currency}")

    # The catalog reuses `local swords = cat(...)` inside multiple
    # do/end blocks — one per tier — so a flat var -> tier map collapses
    # them all to the last binding. Walk linearly and resolve each insert
    # against the most recent prior `local X = cat(catalog.<tier>.weapons, '<cat>')`.
    bindings: list[tuple[int, str, str, str]] = []  # (pos, var, tier, category)
    for m in _CAT_BIND_RE.finditer(text):
        var = m.group(1)
        tier = m.group(2)
        category = m.group(3) if m.group(3) is not None else m.group(4)
        if tier in _TIER_ORDER:
            bindings.append((m.start(), var, tier, category))

    tiers: dict[str, dict[str, list[dict]]] = {t: {} for t in _TIER_ORDER}

    for m in _INSERT_RE.finditer(text):
        var, body = m.group(1), m.group(2)
        # Find the latest binding for this var whose position precedes
        # the insert.
        best: tuple[str, str] | None = None
        for pos, b_var, b_tier, b_cat in bindings:
            if b_var == var and pos < m.start():
                best = (b_tier, b_cat)
        if best is None:
            continue
        tier, category = best
        name_m = _NAME_RE.search(body)
        cost_m = _COST_RE.search(body)
        jobs_m = _JOBS_RE.search(body)
        wiki_m = _WIKI_RE.search(body)
        if not (name_m and cost_m):
            continue
        tiers[tier].setdefault(category, []).append({
            "name": _quoted_value(name_m),
            "cost": int(cost_m.group(1)),
            "jobs": _quoted_value(jobs_m) if jobs_m else "",
            "wiki": _quoted_value(wiki_m) if wiki_m else None,
        })

    page = docs_dir / "progression" / "gear-vendors.md"
    content = _render_weapons_slots(tiers, tier_currency)
    if write_between_markers(page, "weapons-slots", content):
        n = sum(len(rs) for cat_map in tiers.values() for rs in cat_map.values())
        print(f"[weapons_npc] weapons-slots: {n} weapons written (category-first)")
    else:
        print(f"[weapons_npc] weapons-slots: skipped (marker not found in {page.name}); "
              f"add DOCGEN markers to {page} to enable")


def _escape_md(s: str) -> str:
    return s.replace("|", "\\|").replace("\n", " ")


def _item_link(name: str, wiki: str | None) -> str:
    """Render the item name as a BG-Wiki link with a data-img tooltip."""
    page_url, image_url = urls_for_item(name, wiki)
    return (
        f'<a class="item-link" href="{page_url}" '
        f'data-img="{image_url}" target="_blank" rel="noopener">'
        f'{_escape_md(name)}</a>'
    )


def _render_weapons_slots(tiers: dict[str, dict[str, list[dict]]], tier_currency: dict) -> str:
    """Category-first render: one table per weapon category, all tiers
    together, tier shown as a pill column. `tiers` is {tier: {category: [rows]}}."""
    per_tier = {t: sum(len(rs) for rs in tiers[t].values()) for t in _TIER_ORDER}
    total = sum(per_tier.values())
    if total == 0:
        return "_No weapons defined in the catalog yet._"

    lines: list[str] = [
        tier_summary(per_tier, "weapons"),
        "",
        tier_legend(tier_currency, _WEAPONS_TIER_DESC),
        "",
    ]

    # Known category order first, then any unexpected leftovers, so a new
    # category added to the catalog still renders (at the end) rather than
    # vanishing.
    present = {c for t in _TIER_ORDER for c, rs in tiers[t].items() if rs}
    ordered = [c for c in _CATEGORY_ORDER if c in present]
    ordered += [c for c in present if c not in _CATEGORY_ORDER]

    for category in ordered:
        cat_rows = [(t, r) for t in _TIER_ORDER for r in tiers[t].get(category, [])]
        if not cat_rows:
            continue
        lines.append(f"### {category}")
        lines.append("")
        lines.append("| Item | Tier | Cost | Jobs |")
        lines.append("|---|---|--:|---|")
        for tier, row in cat_rows:
            jobs = row["jobs"] if row["jobs"] else "all"
            pill = tier_pill(tier, tier_currency.get(tier))
            lines.append(
                f"| {_item_link(row['name'], row['wiki'])} | {pill} "
                f"| {row['cost']} | {_escape_md(jobs)} |"
            )
        lines.append("")

    return "\n".join(lines).rstrip()
