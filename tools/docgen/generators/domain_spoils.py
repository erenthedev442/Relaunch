"""Generate the Domain Quartermaster section on docs/endgame/domain-invasion.md.

Reads ``modules/custom/lua/domain_spoils_catalog.lua`` -- the catalog the live
Domain Quartermaster NPC (DomainSpoils_NPC.lua) actually serves -- and fills
the "domain-spoils" marker block with the vendor's full stock: every Zurim
Domain-Points item (Hervor/Heidrek/Angantyr sets, Geas Fete weapons, skill
earrings, Reisenjima bases and more) purchasable for HUNT MARKS. It is the
marks-based alternative to grinding Zurim's daily-capped Domain Points:
pricing is Domain-Point cost x ~2.5, but marks have no daily cap.

Renders one table per category (Weapons / Armor / Accessories), ordered the
same way as the NPC's browse menus, with FFXIAH item links keyed on the
catalog's explicit item ids. Fail-closed: a zero-row parse leaves the page
untouched instead of publishing an empty section.

Marker ID: "domain-spoils"
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers
from tools.docgen._bgwiki import urls_for_item
from tools.docgen._luaparse import section, commafy

# The Quartermaster's hub is never hardcoded (custom NPCs get consolidated
# between hubs); npc_location_inject expands this from the SAME catalog's
# npcPos on every build.
_LOC = "{{npc:domain_quartermaster}}"

# CharVar -> player-facing currency name.
_CURRENCY_NAMES = {"HL_Points": "Hunt Marks"}
_CURRENCY_CV_RE = re.compile(r"\bcurrencyCv\s*=\s*['\"]([^'\"]+)['\"]")

# Every vendorItems row is written in this exact field order.
_ROW_RE = re.compile(
    r"\{\s*id\s*=\s*(\d+)\s*,\s*cat\s*=\s*'([^']+)'\s*,\s*"
    r"sub\s*=\s*'([^']+)'\s*,\s*name\s*=\s*'([^']+)'\s*,\s*cost\s*=\s*(\d+)"
)

# Mirror DomainSpoils_NPC.lua's browse-menu ordering; subtypes the NPC learns
# at runtime (e.g. Voluspa) sort after the known ones, alphabetically.
_CAT_ORDER = ["Weapons", "Armor", "Accessories"]
_SUB_ORDER = {
    "Weapons":     ["Fete T2", "Reisenjima", "Grip-Shield", "Ammo"],
    "Armor":       ["Head", "Body", "Hands", "Legs", "Feet"],
    "Accessories": ["Ear", "Neck", "Ring", "Waist", "Back"],
}

# Pricing rule from the catalog header: marks = Zurim Domain-Point cost x 2.5.
_DP_PER_MARK = 2.5


def _escape_md(s: str) -> str:
    return s.replace("|", "\\|").replace("\n", " ")


def _item_link(name: str, item_id: int) -> str:
    """FFXIAH link with a data-img tooltip, matching the other vendor tables."""
    page_url, image_url = urls_for_item(name, None, item_id=item_id)
    return (
        f'<a class="item-link" href="{page_url}" '
        f'data-img="{image_url}" target="_blank" rel="noopener">'
        f'{_escape_md(name)}</a>'
    )


def _parse_items(text: str) -> list[dict]:
    block = section(text, "catalog.vendorItems")
    return [
        {
            "id":   int(iid),
            "cat":  cat,
            "sub":  sub,
            "name": name,
            "cost": int(cost),
        }
        for iid, cat, sub, name, cost in _ROW_RE.findall(block)
    ]


def _sub_key(cat: str, sub: str) -> tuple:
    known = _SUB_ORDER.get(cat, [])
    return (known.index(sub), "") if sub in known else (len(known), sub)


def _render_category(cat: str, items: list[dict], currency: str) -> list[str]:
    items = sorted(items, key=lambda it: (_sub_key(cat, it["sub"]), it["cost"], it["name"]))
    lines = [
        f"### {cat}",
        "",
        f"| Item | Type | {currency} |",
        "|---|---|---:|",
    ]
    for it in items:
        lines.append(
            f"| {_item_link(it['name'], it['id'])} | {it['sub']} | {commafy(it['cost'])} |"
        )
    return lines


def _render_tiers(items: list[dict], currency: str) -> list[str]:
    tiers = sorted({it["cost"] for it in items})
    lines = [
        f"Pricing follows one rule: **{currency} cost = Zurim's Domain-Point "
        f"cost × {_DP_PER_MARK:g}**. Domain Points are daily-capped; marks are not.",
        "",
        f"| Zurim price (Domain Points) | Quartermaster price ({currency}) | Items |",
        "|---:|---:|---:|",
    ]
    for cost in tiers:
        n = sum(1 for it in items if it["cost"] == cost)
        lines.append(
            f"| {commafy(cost / _DP_PER_MARK)} DP | {commafy(cost)} | {n} |"
        )
    return lines


def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/domain_spoils_catalog.lua")
    if src is None:
        print("[domain_spoils] skip: domain_spoils_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")
    cm = _CURRENCY_CV_RE.search(text)
    cv = cm.group(1) if cm else "HL_Points"
    currency = _CURRENCY_NAMES.get(cv, cv)

    items = _parse_items(text)
    if not items:
        print("[domain_spoils] 0 items parsed; leaving page untouched (parser drift?)")
        return

    by_cat: dict[str, list[dict]] = {}
    for it in items:
        by_cat.setdefault(it["cat"], []).append(it)
    cats = [c for c in _CAT_ORDER if c in by_cat] + sorted(
        c for c in by_cat if c not in _CAT_ORDER
    )

    lines: list[str] = [
        f"The **Domain Quartermaster** stands at {_LOC} (`!hub`) and sells the "
        f"entire Zurim Domain-Points catalog for **{currency}** — the currency "
        f"earned from [Hunting League](../progression/index.md) NM kills, Weekly "
        f"Hunts, wave events, and dailies. Everything Zurim sells for daily-capped "
        f"Domain Points is also here for marks, so you can keep gearing after "
        f"you've hit the day's Domain-Point ceiling. "
        f"_{len(items)} items across {len(cats)} categories._",
        "",
    ]
    lines.extend(_render_tiers(items, currency))
    for cat in cats:
        lines.append("")
        lines.extend(_render_category(cat, by_cat[cat], currency))

    content = "\n".join(lines).rstrip()
    page = docs_dir / "endgame" / "domain-invasion.md"
    if write_between_markers(page, "domain-spoils", content):
        counts = " / ".join(f"{cat} {len(by_cat[cat])}" for cat in cats)
        print(f"[domain_spoils] domain-spoils: {len(items)} items ({counts})")
    else:
        print(f"[domain_spoils] domain-spoils: markers not found in {page.name}")
