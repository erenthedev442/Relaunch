"""Generate Armor NPC tables inside docs/progression/gear-vendors.md.

Reads `modules/custom/lua/armor_catalog.lua` and writes one marker block
per tier (bronze/silver/gold). Each tier renders five tables, one per
slot (head/body/hands/legs/feet).

Marker IDs:
  - "armor-bronze"
  - "armor-silver"
  - "armor-gold"

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


# Lua string literal in single or double quotes; supports escapes inside
# single-quoted strings (e.g. 'Adhemar Wrist. +1').
_QUOTED = r"(?:'((?:[^'\\]|\\.)*)'|\"([^\"]*)\")"
_NAME_RE = re.compile(r"\bname\s*=\s*" + _QUOTED)
_COST_RE = re.compile(r"\bcost\s*=\s*(\d+)")
_JOBS_RE = re.compile(r"\bjobs\s*=\s*" + _QUOTED)
_WIKI_RE = re.compile(r"\bwiki\s*=\s*" + _QUOTED)

# Matches lines like:  table.insert(b.head, { id = ..., name = '...', cost = N, jobs = '...' })
# Group 1: variable (b/s/g), group 2: slot (head/body/...), group 3: row body
_INSERT_RE = re.compile(
    r"table\.insert\(\s*(\w+)\.(\w+)\s*,\s*\{(.*?)\}\s*\)",
    re.DOTALL,
)
# Maps the local short var to its tier:  local b = catalog.bronze
_BIND_RE = re.compile(r"local\s+(\w+)\s*=\s*catalog\.(\w+)\b")

_SLOT_ORDER = ("head", "body", "hands", "legs", "feet", "shields")
_SLOT_LABEL = {
    "head": "Head",
    "body": "Body",
    "hands": "Hands",
    "legs": "Legs",
    "feet": "Feet",
    "shields": "Shields",
}
_TIER_ORDER = ("bronze", "silver", "gold")

# Short per-tier descriptions shown in the legend under the Armor heading —
# these carry the context the old per-tier `### <tier> tier (…)` headings did.
_ARMOR_TIER_DESC = {
    "bronze": "entry ilvl 119",
    "silver": "HQ +1 / +2 augmented",
    "gold":   "BiS (Volte / Omen bodies / exclusives)",
}

# Fallback if the catalog doesn't expose a seals table — these match the
# upstream defaults so the page still renders something sensible.
_FALLBACK_CURRENCY = {
    "bronze": "Beastmen's Seal",
    "silver": "Kindred's Seal",
    "gold":   "Abdhaljs Seal",
}


# Parse `catalog.seals = { bronze = { id = N, name = "X" }, ... }` from the
# Lua catalog source. Returns {tier: name} populated for whichever tiers
# were found; missing tiers fall back to _FALLBACK_CURRENCY at lookup time.
_SEAL_TIER_RE = re.compile(
    r"(bronze|silver|gold)\s*=\s*\{[^}]*?name\s*=\s*['\"]([^'\"]+)['\"]",
)

def _parse_tier_currency(catalog_text: str) -> dict:
    found = {}
    for m in _SEAL_TIER_RE.finditer(catalog_text):
        found[m.group(1)] = m.group(2)
    return found


# Parse `catalog.goldExtraDrop = { id = X, qty = Y, name = 'Z' }` so the
# Gold-tier extra-requirement line can quote the live name + qty.
_GOLD_EXTRA_RE = re.compile(
    r"catalog\.goldExtraDrop\s*=\s*\{[^}]*?"
    r"qty\s*=\s*(\d+)[^}]*?"
    r"name\s*=\s*['\"]([^'\"]+)['\"]",
    re.DOTALL,
)

# Parse `catalog.vendorPos = { x = N, y = N, z = N, rot = N }` so the
# Location table in gear-vendors.md tracks the catalog. Returns (x, y, z)
# as floats or None if not found. (rot omitted — not displayed.)
_VENDOR_POS_RE = re.compile(
    r"catalog\.vendorPos\s*=\s*\{[^}]*?"
    r"x\s*=\s*(-?[\d.]+)[^}]*?"
    r"y\s*=\s*(-?[\d.]+)[^}]*?"
    r"z\s*=\s*(-?[\d.]+)",
    re.DOTALL,
)

# Same shape but rooted at `accessoriesPos` (no `catalog.` prefix). This is
# the Hunting League catalog's "Hunt Accessories" REWARD-SHOP NPC position —
# a different NPC from the medal Accessories Vendor. Kept only as a FALLBACK
# for the vendors-intro table when accessory_catalog.lua (the Accessories
# Vendor's real spawn source) can't be resolved.
_ACC_POS_RE = re.compile(
    r"\baccessoriesPos\s*=\s*\{[^}]*?"
    r"x\s*=\s*(-?[\d.]+)[^}]*?"
    r"y\s*=\s*(-?[\d.]+)[^}]*?"
    r"z\s*=\s*(-?[\d.]+)",
    re.DOTALL,
)

def _parse_vendor_pos(catalog_text: str) -> tuple[float, float, float] | None:
    m = _VENDOR_POS_RE.search(catalog_text)
    if not m:
        return None
    return float(m.group(1)), float(m.group(2)), float(m.group(3))


def _parse_accessories_pos(hl_text: str) -> tuple[float, float, float] | None:
    m = _ACC_POS_RE.search(hl_text)
    if not m:
        return None
    return float(m.group(1)), float(m.group(2)), float(m.group(3))


# Parse `catalog.zonePath = 'xi.zones.<ZoneName>'`. Returns the bare zone
# name with underscores converted to spaces ("Reisenjima_Henge" -> "Reisenjima Henge")
# or None if not found.
_ZONE_PATH_RE = re.compile(
    r"catalog\.zonePath\s*=\s*['\"]xi\.zones\.([^'\"]+)['\"]",
)

def _parse_zone_display(catalog_text: str) -> str | None:
    m = _ZONE_PATH_RE.search(catalog_text)
    if not m:
        return None
    return m.group(1).replace("_", " ")

def _parse_gold_extra(catalog_text: str) -> tuple[int, str] | None:
    m = _GOLD_EXTRA_RE.search(catalog_text)
    if not m:
        return None
    return int(m.group(1)), m.group(2)


# Parse the Hunting League catalog's Seals shop entries so the Currencies
# table can quote the live Hunt-Mark cost per tier instead of hardcoded
# prose. Looks for entries shaped like:
#   { name = "<Medal Name>",  id = N, cost = N, ... }
# inside the rewardCategories block.
_HL_SEAL_ROW_RE = re.compile(
    r"\{\s*name\s*=\s*['\"]([^'\"]+)['\"]\s*,\s*id\s*=\s*\d+\s*,\s*cost\s*=\s*(\d+)",
)

def _parse_hl_seal_costs(hl_text: str) -> dict[str, int]:
    """Return {currency_name: hunt_mark_cost} for every shop row found."""
    out: dict[str, int] = {}
    for m in _HL_SEAL_ROW_RE.finditer(hl_text):
        out[m.group(1)] = int(m.group(2))
    return out


def _quoted_value(m: re.Match) -> str:
    raw = m.group(1) if m.group(1) is not None else m.group(2)
    return raw.replace("\\'", "'").replace('\\"', '"').replace("\\\\", "\\")


def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/armor_catalog.lua")
    if src is None:
        print("[armor_npc] skip: armor_catalog.lua not found")
        return

    text = src.read_text(encoding="utf-8", errors="replace")

    # Pull seal/currency names from the catalog so renaming Bronze/Silver/Gold
    # currencies in armor_catalog.lua propagates to the docs automatically.
    parsed_currency = _parse_tier_currency(text)
    tier_currency = {
        t: parsed_currency.get(t, _FALLBACK_CURRENCY[t]) for t in _TIER_ORDER
    }
    print(f"[armor_npc] tier currencies: {tier_currency}")

    # Pull the Gold-tier extra-drop requirement (Riftborn Boulder by default).
    # Used in the Currencies table footer and the Gold tier render.
    gold_extra = _parse_gold_extra(text)
    if gold_extra:
        print(f"[armor_npc] gold extra-drop: {gold_extra[0]}× {gold_extra[1]}")

    # Pull seal Hunt-Mark costs from hunting_league_catalog.lua so the
    # "Where it drops" column reflects the actual exchange rate rather
    # than static prose.
    hl_src = resolve_source(repo_root, "modules/custom/lua/hunting_league_catalog.lua")
    hl_seal_costs: dict[str, int] = {}
    if hl_src is not None:
        hl_text = hl_src.read_text(encoding="utf-8", errors="replace")
        hl_seal_costs = _parse_hl_seal_costs(hl_text)
        print(f"[armor_npc] HL seal costs: {hl_seal_costs}")
    else:
        print("[armor_npc] hunting_league_catalog.lua not found — using generic drop descriptions")

    # Pull the per-click multi-buy cap from HuntingLeague.lua. The seal
    # preview menu (buildItemPreviewMenu) gates on `isSealsCat(catIdx)`
    # and renders Buy 1 / Buy 10 / Buy max rows where max is clamped to
    # SEAL_STACK_CAP. We surface both the fact-of-multi-buy and the cap
    # value so the docs can never claim something the code doesn't do.
    hl_module_src = resolve_source(repo_root, "modules/custom/lua/HuntingLeague.lua")
    seal_stack_cap: int | None = None
    seal_multi_buy = False
    if hl_module_src is not None:
        hl_module_text = hl_module_src.read_text(encoding="utf-8", errors="replace")
        cap_m = re.search(r"^\s*local\s+SEAL_STACK_CAP\s*=\s*(\d+)",
                          hl_module_text, re.MULTILINE)
        if cap_m:
            seal_stack_cap = int(cap_m.group(1))
        # Detect the multi-buy branch by looking for the literal Buy-10
        # row that only the seals path emits. Far more robust than parsing
        # the full preview-menu code.
        seal_multi_buy = "Buy 10  [" in hl_module_text and "isSealsCat" in hl_module_text
        print(f"[armor_npc] seal multi-buy: enabled={seal_multi_buy}, cap={seal_stack_cap}")

    # Pull NPC location data: zone name + vendor positions for the
    # top-of-page intro/location table. Armor catalog supplies the zone +
    # Armor Vendor coords; the weapons catalog supplies the Weapons Vendor
    # coords.
    zone_display = _parse_zone_display(text) or "Unknown Zone"
    armor_pos = _parse_vendor_pos(text)
    weapons_pos = None
    weapons_src = resolve_source(repo_root, "modules/custom/lua/gear_progression_catalog.lua")
    if weapons_src is not None:
        weapons_pos = _parse_vendor_pos(weapons_src.read_text(encoding="utf-8", errors="replace"))

    # The Accessories Vendor spawns from its OWN catalog's vendorPos
    # (accessory_catalog.lua — the file Accessory_NPC.lua reads at boot).
    # Do NOT use hunting_league_catalog.accessoriesPos here: that places a
    # DIFFERENT NPC (the "Hunt Accessories" Hunt-Marks reward shop, 3 units
    # west). It remains only as a fallback if the accessory catalog is
    # missing from the live tree.
    accessories_pos = None
    acc_src = resolve_source(repo_root, "modules/custom/lua/accessory_catalog.lua")
    if acc_src is not None:
        accessories_pos = _parse_vendor_pos(acc_src.read_text(encoding="utf-8", errors="replace"))
    if accessories_pos is None and hl_src is not None:
        accessories_pos = _parse_accessories_pos(hl_text)

    print(
        f"[armor_npc] zone={zone_display!r}, armor_pos={armor_pos}, "
        f"weapons_pos={weapons_pos}, accessories_pos={accessories_pos}"
    )

    # Build variable -> tier map.
    bindings: dict[str, str] = {}
    for m in _BIND_RE.finditer(text):
        var, tier = m.group(1), m.group(2)
        if tier in _TIER_ORDER:
            bindings[var] = tier

    # Bucket rows by tier and slot.
    tiers: dict[str, dict[str, list[dict]]] = {
        t: {s: [] for s in _SLOT_ORDER} for t in _TIER_ORDER
    }

    for m in _INSERT_RE.finditer(text):
        var, slot, body = m.group(1), m.group(2), m.group(3)
        tier = bindings.get(var)
        if tier is None or slot not in _SLOT_ORDER:
            continue
        name_m = _NAME_RE.search(body)
        cost_m = _COST_RE.search(body)
        jobs_m = _JOBS_RE.search(body)
        wiki_m = _WIKI_RE.search(body)
        if not (name_m and cost_m):
            continue
        tiers[tier][slot].append({
            "name": _quoted_value(name_m),
            "cost": int(cost_m.group(1)),
            "jobs": _quoted_value(jobs_m) if jobs_m else "",
            "wiki": _quoted_value(wiki_m) if wiki_m else None,
        })

    page = docs_dir / "progression" / "gear-vendors.md"

    # Fill the top-of-page intro + NPC location table so the zone name
    # and (x, y, z) coordinates always match the catalogs' vendorPos.
    intro_content = _render_vendors_intro(zone_display, armor_pos, weapons_pos, accessories_pos)
    if write_between_markers(page, "vendors-intro", intro_content):
        print(f"[armor_npc] vendors-intro: zone + location table updated")
    else:
        print(f"[armor_npc] vendors-intro: skipped (markers not found in {page.name})")

    # Fill the top-of-page Currencies table so the displayed seal names
    # always match catalog.seals.<tier>.name AND the "Where it drops"
    # column reflects the live Hunt-Mark exchange rate.
    currencies_content = _render_currencies_table(
        tier_currency, hl_seal_costs, gold_extra,
        seal_multi_buy=seal_multi_buy,
        seal_stack_cap=seal_stack_cap,
    )
    if write_between_markers(page, "currencies", currencies_content):
        print(f"[armor_npc] currencies: table updated ({list(tier_currency.values())})")
    else:
        print(f"[armor_npc] currencies: skipped (markers not found in {page.name})")

    # Slot-first render: one table per slot (Head/Body/…/Shields) with the
    # tier shown as a pill column. The Gold-tier extra-drop requirement moves
    # into an admonition inside this block (there's no longer a Gold section
    # to sit above), and it's also stated in the top-of-page Currencies table.
    content = _render_armor_slots(tiers, tier_currency, gold_extra)
    if write_between_markers(page, "armor-slots", content):
        rows = sum(len(rs) for slot_map in tiers.values() for rs in slot_map.values())
        print(f"[armor_npc] armor-slots: {rows} pieces written (slot-first)")
    else:
        print(f"[armor_npc] armor-slots: skipped (marker not found in {page.name}); "
              f"add DOCGEN markers to {page} to enable")


def _escape_md(s: str) -> str:
    return s.replace("|", "\\|").replace("\n", " ")


def _item_link(name: str, wiki: str | None) -> str:
    """Render the item name as a BG-Wiki link with a data-img tooltip."""
    page_url, image_url = urls_for_item(name, wiki)
    # Pipes/quotes in URLs/attributes would break the markdown table cell;
    # attribute values are pre-escaped because the inputs come from a
    # closed set of catalog data and we control the encoding.
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


def _render_vendors_intro(
    zone_display: str,
    armor_pos: tuple[float, float, float] | None,
    weapons_pos: tuple[float, float, float] | None,
    accessories_pos: tuple[float, float, float] | None = None,
) -> str:
    """Page intro paragraph + the NPC location table. All three positions
    pull from their respective catalogs' vendorPos / accessoriesPos, so
    moving the NPCs propagates to the docs without manual edits."""
    lines = [
        (
            f"Three custom NPCs at **{zone_display}** sell endgame gear for "
            f"currency you'll already be earning from regular content. All "
            f"three stand on the same row next to the [Hunting League](index.md) "
            f"NPCs in the same zone — one trip covers your full progression loop."
        ),
        "",
        f"| NPC | Location ({zone_display}) | Sells |",
        "|---|---|---|",
        f"| **Armor Vendor** | {_fmt_pos(armor_pos)} | Head / Body / Hands / Legs / Feet |",
        f"| **Weapons Vendor** | {_fmt_pos(weapons_pos)} | Every weapon category, all jobs |",
        f"| **Accessories Vendor** | {_fmt_pos(accessories_pos)} | Neck / Earrings / Rings / Back / Waist |",
    ]
    return "\n".join(lines)


def _render_currencies_table(
    tier_currency: dict,
    hl_seal_costs: dict[str, int],
    gold_extra: tuple[int, str] | None,
    seal_multi_buy: bool = False,
    seal_stack_cap: int | None = None,
) -> str:
    """Top-of-page Currencies table. EVERY column is derived:
      - Tier            : fixed enum (Bronze/Silver/Gold)
      - Currency        : catalog.seals[tier].name
      - How to get      : Hunt-Mark cost from hunting_league_catalog.lua (if found)
      - Gold extra      : catalog.goldExtraDrop (qty + name)
      - Multi-buy note  : presence + cap detected from HuntingLeague.lua source
    """
    lines = [
        "Both vendors use the same three currencies, tier-gated:",
        "",
        "| Tier | Currency | How to get |",
        "|---|---|---|",
    ]
    for tier_key in _TIER_ORDER:
        currency = tier_currency.get(tier_key, _FALLBACK_CURRENCY[tier_key])
        cost = hl_seal_costs.get(currency)
        if cost is not None:
            how = f"{cost} Hunt Marks at the Hunting League Seals NPC"
        else:
            how = "Earned via the Hunting League"   # generic fallback
        lines.append(
            f"| **{tier_key.capitalize()}** | {currency} | {how} |"
        )
    lines.append("")
    if seal_multi_buy:
        # Render only when the multi-buy branch actually exists in the
        # source. Avoids claiming a feature the code doesn't deliver.
        if seal_stack_cap:
            lines.append(
                f"!!! tip \"Buy seals in bulk\"\n"
                f"    The Seals NPC supports multi-quantity purchases — when previewing a seal, "
                f"you'll see **Buy 1**, **Buy 10**, and **Buy max** options. The max is computed "
                f"live from your mark balance and is capped at **{seal_stack_cap} per click** "
                f"(one full inventory stack). Click again to grab another stack."
            )
        else:
            lines.append(
                "!!! tip \"Buy seals in bulk\"\n"
                "    The Seals NPC supports multi-quantity purchases — when previewing a seal, "
                "you'll see **Buy 1**, **Buy 10**, and **Buy max** options. The max is computed "
                "live from your mark balance and is capped at one full inventory stack per click."
            )
        lines.append("")
    if gold_extra is not None:
        qty, name = gold_extra
        lines.append(
            f"**Gold-tier armor pieces** require an additional **{qty} {name}** "
            "per piece on top of the seal cost."
        )
    return "\n".join(lines)


def _render_armor_slots(
    tiers: dict[str, dict[str, list[dict]]],
    tier_currency: dict,
    gold_extra: tuple[int, str] | None,
) -> str:
    """Slot-first render: one table per slot, all tiers together, tier shown
    as a pill column. `tiers` is {tier: {slot: [rows]}}."""
    per_tier = {t: sum(len(tiers[t][s]) for s in _SLOT_ORDER) for t in _TIER_ORDER}

    lines: list[str] = [
        tier_summary(per_tier, "pieces"),
        "",
        tier_legend(tier_currency, _ARMOR_TIER_DESC),
        "",
    ]

    if gold_extra is not None:
        qty, name = gold_extra
        gold_cur = tier_currency.get("gold", _FALLBACK_CURRENCY["gold"])
        lines.append('!!! warning "Gold tier — extra cost"')
        lines.append(
            f"    Every \U0001F947 **Gold** piece also requires "
            f"**{qty} {name}** on top of the {gold_cur} cost."
        )
        lines.append("")

    for slot in _SLOT_ORDER:
        # All tiers for this slot, ordered bronze -> silver -> gold so the
        # table reads cheapest -> best top to bottom.
        slot_rows = [(t, r) for t in _TIER_ORDER for r in tiers[t][slot]]
        if not slot_rows:
            continue
        lines.append(f"### {_SLOT_LABEL[slot]}")
        lines.append("")
        lines.append("| Item | Tier | Cost | Jobs |")
        lines.append("|---|---|--:|---|")
        for tier, row in slot_rows:
            jobs = row["jobs"] if row["jobs"] else "all"
            pill = tier_pill(tier, tier_currency.get(tier))
            lines.append(
                f"| {_item_link(row['name'], row['wiki'])} | {pill} "
                f"| {row['cost']} | {_escape_md(jobs)} |"
            )
        lines.append("")

    return "\n".join(lines).rstrip()
