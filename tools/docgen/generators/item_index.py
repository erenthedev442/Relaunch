"""Generate the Item Finder index on docs/progression/item-finder.md.

A single alphabetical "where do I get it" table that aggregates every
purchasable item across all four vendor catalogs into one searchable list:

  * Armor Vendor        (armor_catalog.lua)
  * Weapons Vendor      (gear_progression_catalog.lua)
  * Accessories Vendor  (accessory_catalog.lua)
  * Infamy Vendor       (infamy_vendor_catalog.lua — curated + auto-promoted BiS)

It deliberately does **not** re-implement the catalog parsers. Each of the
per-vendor generators already parses its catalog for the gear-vendors.md /
dungeons.md pages, so this module imports their extractors (accessory_npc /
dungeons) and their field regexes (armor_npc / weapons_npc) and reuses them.
That keeps the finder from ever drifting away from the vendor pages: a field
rename that breaks one breaks both, and both get fixed in one place.

Each row links the item name to BG-Wiki (stats) and its Source to the exact
vendor section on the existing pages. Cost carries the currency name because
every tier is paid in a different seal/medal.

The catalogs are normally gitignored (live-only), so this runs against
``$LEGENDARY_LIVE_ROOT``. If *no* catalog resolves (e.g. CI without that env
var) — or they resolve but parse to zero rows (parser drift) — the page is
left exactly as it was rather than being blanked, matching the no-regression
discipline the other catalog generators use.
"""
from __future__ import annotations

from collections import Counter
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._bgwiki import urls_for_item

# Reuse sibling extractors + regexes so the finder can't drift from the
# vendor pages. The field regexes (name/cost/jobs/wiki) are byte-identical
# across armor_npc and weapons_npc, so we import one copy from armor_npc.
from tools.docgen.generators import accessory_npc, dungeons
from tools.docgen.generators.armor_npc import (
    _BIND_RE as _ARMOR_BIND_RE,
    _INSERT_RE as _ARMOR_INSERT_RE,
    _NAME_RE, _COST_RE, _JOBS_RE, _WIKI_RE,
    _quoted_value,
    _SLOT_LABEL as _ARMOR_SLOT_LABEL,
    _parse_tier_currency,
    _FALLBACK_CURRENCY as _SEAL_FALLBACK,
)
from tools.docgen.generators.weapons_npc import (
    _CAT_BIND_RE as _WPN_BIND_RE,
    _INSERT_RE as _WPN_INSERT_RE,
)


_GEAR_PAGE = "gear-vendors.md"
_TIER_LABEL = {"bronze": "Bronze", "silver": "Silver", "gold": "Gold"}

# Catalog paths, in display order. Used both to resolve sources and to
# decide whether to skip (no source found -> leave page untouched).
_CATALOGS = {
    "armor":       "modules/custom/lua/armor_catalog.lua",
    "weapons":     "modules/custom/lua/gear_progression_catalog.lua",
    "accessories": "modules/custom/lua/accessory_catalog.lua",
    "infamy":      "modules/custom/lua/infamy_vendor_catalog.lua",
}

# Stable order for the per-source count summary line.
_SOURCE_ORDER = ("Armor Vendor", "Weapons Vendor", "Accessories Vendor", "Infamy Vendor")


def _escape_md(s: str) -> str:
    return s.replace("|", "\\|").replace("\n", " ")


def _row(name, cost, currency, jobs, wiki, source, anchor, detail) -> dict:
    return {
        "name": name, "cost": cost, "currency": currency, "jobs": jobs,
        "wiki": wiki, "source": source, "anchor": anchor, "detail": detail,
    }


def _collect_armor(src: Path) -> list:
    text = src.read_text(encoding="utf-8", errors="replace")
    currency = _parse_tier_currency(text)
    var_tier = {
        m.group(1): m.group(2)
        for m in _ARMOR_BIND_RE.finditer(text)
        if m.group(2) in _TIER_LABEL
    }
    rows = []
    for m in _ARMOR_INSERT_RE.finditer(text):
        var, slot, body = m.group(1), m.group(2), m.group(3)
        tier = var_tier.get(var)
        if tier is None or slot not in _ARMOR_SLOT_LABEL:
            continue
        name_m, cost_m = _NAME_RE.search(body), _COST_RE.search(body)
        if not (name_m and cost_m):
            continue
        jobs_m, wiki_m = _JOBS_RE.search(body), _WIKI_RE.search(body)
        rows.append(_row(
            _quoted_value(name_m), int(cost_m.group(1)),
            currency.get(tier, _SEAL_FALLBACK[tier]),
            _quoted_value(jobs_m) if jobs_m else "",
            _quoted_value(wiki_m) if wiki_m else None,
            "Armor Vendor", f"{_GEAR_PAGE}#armor-vendor",
            f"{_TIER_LABEL[tier]} · {_ARMOR_SLOT_LABEL[slot]}",
        ))
    return rows


def _collect_weapons(src: Path) -> list:
    text = src.read_text(encoding="utf-8", errors="replace")
    currency = _parse_tier_currency(text)
    # Positional bindings: `local swords = cat(catalog.bronze.weapons, 'Swords')`
    # appears once per tier, so resolve each insert against the most recent
    # prior binding of its var (mirrors weapons_npc.generate).
    binds = []
    for m in _WPN_BIND_RE.finditer(text):
        tier = m.group(2)
        category = m.group(3) if m.group(3) is not None else m.group(4)
        if tier in _TIER_LABEL:
            binds.append((m.start(), m.group(1), tier, category))
    rows = []
    for m in _WPN_INSERT_RE.finditer(text):
        var, body = m.group(1), m.group(2)
        best = None
        for pos, b_var, b_tier, b_cat in binds:
            if b_var == var and pos < m.start():
                best = (b_tier, b_cat)
        if best is None:
            continue
        tier, category = best
        name_m, cost_m = _NAME_RE.search(body), _COST_RE.search(body)
        if not (name_m and cost_m):
            continue
        jobs_m, wiki_m = _JOBS_RE.search(body), _WIKI_RE.search(body)
        rows.append(_row(
            _quoted_value(name_m), int(cost_m.group(1)),
            currency.get(tier, _SEAL_FALLBACK[tier]),
            _quoted_value(jobs_m) if jobs_m else "",
            _quoted_value(wiki_m) if wiki_m else None,
            "Weapons Vendor", f"{_GEAR_PAGE}#weapons-vendor",
            f"{_TIER_LABEL[tier]} · {category}",
        ))
    return rows


def _collect_accessories(src: Path) -> list:
    text = src.read_text(encoding="utf-8", errors="replace")
    currency = accessory_npc._parse_tier_currency(text)
    by_tier = accessory_npc._extract(text)   # {tier: {slot: [rows]}}
    rows = []
    for tier, slots in by_tier.items():
        for slot, items in slots.items():
            for it in items:
                rows.append(_row(
                    it["name"], it["cost"],
                    currency.get(tier, accessory_npc._FALLBACK_CURRENCY[tier]),
                    it.get("jobs", ""), None,
                    "Accessories Vendor", f"{_GEAR_PAGE}#accessory-npc-medal-paid-jewelry",
                    f"{_TIER_LABEL.get(tier, tier.capitalize())} · "
                    f"{accessory_npc._SLOT_LABEL.get(slot, slot.capitalize())}",
                ))
    return rows


def _collect_infamy(src: Path) -> list:
    text = src.read_text(encoding="utf-8", errors="replace")
    cm = dungeons._CURRENCY_NAME_RE.search(text)
    currency = dungeons._quoted_value(cm) if cm else "Infamy"
    anchor = f"{_GEAR_PAGE}#infamy-vendor"
    rows = []
    for it in dungeons._extract_vendor_items(text):
        rows.append(_row(it["name"], it["cost"], currency, "", None,
                         "Infamy Vendor", anchor, "Curated"))
    for it in dungeons._extract_vendor_items_block(text, "catalog.vendorItemsAuto"):
        rows.append(_row(it["name"], it["cost"], currency, "", None,
                         "Infamy Vendor", anchor, "Auto BiS"))
    return rows


_COLLECTORS = {
    "armor":       _collect_armor,
    "weapons":     _collect_weapons,
    "accessories": _collect_accessories,
    "infamy":      _collect_infamy,
}


def _render(rows: list) -> str:
    rows_sorted = sorted(rows, key=lambda r: (r["name"].lower(), r["source"], r["detail"]))
    counts = Counter(r["source"] for r in rows_sorted)
    summary = " · ".join(
        f"**{counts[s]}** {s.replace(' Vendor', '')}"
        for s in _SOURCE_ORDER if counts.get(s)
    )
    lines = [
        f"{len(rows_sorted):,} items in stock — {summary}.",
        "",
        "_This list is **rebuilt from the live vendor catalogs on every deploy**, so it "
        "always reflects current stock (the \"Last updated\" date only moves when the "
        "stock itself changes)._",
        "",
        "| Item | Source | Cost | For |",
        "|---|---|---:|---|",
    ]
    for r in rows_sorted:
        page_url, _img = urls_for_item(r["name"], r["wiki"])
        name_cell = f"[{_escape_md(r['name'])}]({page_url})"
        src_cell = f"[{r['source']}]({r['anchor']}) · {r['detail']}"
        cost_cell = f"{r['cost']:,} {r['currency']}"
        for_cell = _escape_md(r["jobs"]) if r["jobs"] else "—"
        lines.append(f"| {name_cell} | {src_cell} | {cost_cell} | {for_cell} |")
    return "\n".join(lines)


def generate(repo_root: Path, docs_dir: Path) -> None:
    page = docs_dir / "progression" / "item-finder.md"
    if not page.exists():
        print(f"[item_index] skip: page not found ({page})")
        return

    found = {key: resolve_source(repo_root, path) for key, path in _CATALOGS.items()}
    if not any(found.values()):
        print("[item_index] skip: no gear catalogs found (LEGENDARY_LIVE_ROOT unset?) — leaving page as-is")
        return

    rows: list = []
    for key, src in found.items():
        if src is None:
            print(f"[item_index] {key}: catalog not found, skipping that source")
            continue
        try:
            collected = _COLLECTORS[key](src)
            rows += collected
            print(f"[item_index] {key}: {len(collected)} items")
        except Exception as e:  # noqa: BLE001
            print(f"[item_index] {key}: parse failed ({e}) — skipping that source")

    if not rows:
        print("[item_index] skip: catalogs resolved but parsed 0 items — leaving page as-is (possible parser drift)")
        return

    if write_between_markers(page, "item-finder", _render(rows)):
        print(f"[item_index] item-finder: {len(rows)} items written into marker")
    else:
        print(f"[item_index] item-finder: marker missing in {page.name}")
