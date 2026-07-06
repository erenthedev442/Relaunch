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
# gear_progression_catalog.lua propagates here automatically. We isolate the
# `catalog.seals` block FIRST: the tier keys (bronze/silver/gold) are ALSO the
# `catalog.bronze/silver/gold` weapon tables further down, so a whole-file scan
# used to grab the first weapon's name (e.g. "Tokko Knife") as the currency.
_SEALS_BLOCK_RE = re.compile(r"catalog\.seals\s*=\s*\{(.*?)\n\}", re.DOTALL)
_SEAL_TIER_RE = re.compile(
    r"(bronze|silver|gold)\s*=\s*\{[^}]*?name\s*=\s*['\"]([^'\"]+)['\"]",
)

def _parse_tier_currency(catalog_text: str) -> dict:
    block_m = _SEALS_BLOCK_RE.search(catalog_text)
    scope = block_m.group(1) if block_m else catalog_text
    found = {}
    for m in _SEAL_TIER_RE.finditer(scope):
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


# item_weapon.skill id -> weapon category label (matches _CATEGORY_ORDER). The
# flat bronze/silver/gold catalog tiers are plain weapon lists with no category,
# so we derive each weapon's category from its skill to keep the category-grouped
# tables. Instruments and grips (skill 0) get their own buckets so they render.
_SKILL_CATEGORY = {
    1: "Hand-to-Hand", 2: "Daggers", 3: "Swords", 4: "Great Swords",
    5: "Axes", 6: "Great Axes", 7: "Scythes", 8: "Polearms",
    9: "Katana", 10: "Great Katana", 11: "Clubs", 12: "Staves",
    25: "Archery", 26: "Marksmanship", 27: "Marksmanship",
    40: "Instruments", 41: "Instruments", 42: "Instruments", 45: "Instruments",
    0: "Grips",
}
_WEAPON_SKILL_RE = re.compile(
    r"^INSERT INTO `item_weapon` VALUES \((\d+),'[^']*',(\d+),", re.M)
_ID_RE = re.compile(r"\bid\s*=\s*(\d+)")

# The CURRENT bronze/silver/gold tiers are flat literal lists:
#   catalog.bronze = { weapons = { { id=.., name=.., cost=.., jobs=.. }, ... } }
# (The legacy `cat()` + `table.insert` shape is now used ONLY by the inert
# `catalog.infamy` export.) Capture each tier's weapons block, then each entry.
_TIER_WEAPONS_RE = re.compile(
    r"catalog\.(bronze|silver|gold)\s*=\s*\{\s*weapons\s*=\s*\{(.*?)\n\s*\},",
    re.DOTALL,
)
_ENTRY_RE = re.compile(r"\{([^{}]*\bid\s*=\s*\d+[^{}]*)\}")


def _item_categories(repo_root: Path) -> dict:
    """item id -> weapon category label, from sql/item_weapon.sql's skill column."""
    p = resolve_source(repo_root, "sql/item_weapon.sql")
    out: dict[int, str] = {}
    if p is not None:
        for m in _WEAPON_SKILL_RE.finditer(p.read_text(encoding="utf-8", errors="replace")):
            out[int(m.group(1))] = _SKILL_CATEGORY.get(int(m.group(2)), "Other")
    return out


def _row(body: str) -> dict | None:
    name_m = _NAME_RE.search(body)
    cost_m = _COST_RE.search(body)
    if not (name_m and cost_m):
        return None
    id_m = _ID_RE.search(body)
    jobs_m = _JOBS_RE.search(body)
    wiki_m = _WIKI_RE.search(body)
    return {
        "name": _quoted_value(name_m),
        "cost": int(cost_m.group(1)),
        "jobs": _quoted_value(jobs_m) if jobs_m else "",
        "wiki": _quoted_value(wiki_m) if wiki_m else None,
        "id":   int(id_m.group(1)) if id_m else None,
    }


def _parse_flat_tiers(text: str, item_cat: dict) -> dict:
    """bronze/silver/gold flat catalog -> {tier: {category: [rows]}}."""
    tiers = {t: {} for t in _TIER_ORDER}
    for tm in _TIER_WEAPONS_RE.finditer(text):
        tier, body = tm.group(1), tm.group(2)
        for em in _ENTRY_RE.finditer(body):
            row = _row(em.group(1))
            if row is None:
                continue
            category = item_cat.get(row["id"], "Other")
            tiers[tier].setdefault(category, []).append(row)
    return tiers


def _parse_legacy_tiers(text: str, tier_names: tuple) -> dict:
    """Legacy `local x = cat(catalog.<tier>.weapons, '<cat>')` + `table.insert`
    shape (now only the inert `infamy` export uses it)."""
    bindings = []
    for m in _CAT_BIND_RE.finditer(text):
        var, tier = m.group(1), m.group(2)
        category = m.group(3) if m.group(3) is not None else m.group(4)
        if tier in tier_names:
            bindings.append((m.start(), var, tier, category))
    tiers = {t: {} for t in tier_names}
    for m in _INSERT_RE.finditer(text):
        var, body = m.group(1), m.group(2)
        best = None
        for pos, b_var, b_tier, b_cat in bindings:
            if b_var == var and pos < m.start():
                best = (b_tier, b_cat)
        if best is None:
            continue
        tier, category = best
        row = _row(body)
        if row is not None:
            tiers[tier].setdefault(category, []).append(row)
    return tiers


def parse_weapon_tiers(text: str, repo_root: Path, include_infamy: bool = False) -> dict:
    """{tier: {category: [rows]}} for bronze/silver/gold (flat catalog format,
    category derived from each weapon's skill). With include_infamy, also adds the
    legacy `infamy` tier. Shared by weapons_npc (vendor page) and gear_guide_page
    so the two can never disagree about the weapon tiers."""
    item_cat = _item_categories(repo_root)
    tiers = _parse_flat_tiers(text, item_cat)
    if include_infamy:
        tiers["infamy"] = _parse_legacy_tiers(text, ("infamy",)).get("infamy", {})
    return tiers


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

    # bronze/silver/gold weapon tiers (flat catalog format; each weapon's
    # category derived from its skill). Shared with gear_guide_page via
    # parse_weapon_tiers so the vendor page and the gear guide never disagree.
    tiers = parse_weapon_tiers(text, repo_root)

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
