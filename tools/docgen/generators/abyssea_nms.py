"""Generate Abyssea NM fact-blocks inside docs/endgame/abyssea-nms.md.

Reads: modules/custom/lua/AbysseaMarks.lua

Marker IDs:
  - "abyssea-tiers"    -- Zones & Difficulty tiers table
  - "abyssea-rewards"  -- Base rewards, multipliers, full per-tier reward tabs
"""
from __future__ import annotations

import math
import re
from collections import Counter
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers

# ---------------------------------------------------------------------------
# Zone key → player-facing display name (in tier order)
# ---------------------------------------------------------------------------

_ZONE_DISPLAY: dict[str, str] = {
    # Visions of Abyssea
    "ABYSSEA_KONSCHTAT": "Konschtat",
    "ABYSSEA_TAHRONGI":  "Tahrongi",
    "ABYSSEA_LA_THEINE": "La Theine",
    # Scars of Abyssea
    "ABYSSEA_ATTOHWA":   "Attohwa",
    "ABYSSEA_MISAREAUX": "Misareaux",
    "ABYSSEA_VUNKERL":   "Vunkerl",
    # Heroes of Abyssea
    "ABYSSEA_ALTEPA":     "Altepa",
    "ABYSSEA_GRAUBERG":   "Grauberg",
    "ABYSSEA_ULEGUERAND": "Uleguerand",
}

# Multipliers (mirrors the if-conditions in calcMultipliers())
_PARTY_MULT = 2.0
_TRUST_MULT = 1.5

# ---------------------------------------------------------------------------
# Parser
# ---------------------------------------------------------------------------


def _parse_zone_config(text: str) -> list[dict]:
    """Return one dict per configured zone from zoneConfig in AbysseaMarks.lua."""
    results: list[dict] = []
    # Each entry spans multiple lines, e.g.:
    #   [xi.zone.ABYSSEA_KONSCHTAT] = { cost = 200, infamy = 25, gil = 250000, ...
    #     ..., level = 135, maxHP = 4000000, ... }
    entry_re = re.compile(
        r'\[xi\.zone\.(\w+)\]\s*=\s*\{([^}]+)\}',
        re.DOTALL,
    )
    field_re = re.compile(r'\b(\w+)\s*=\s*([\d.]+)')

    for m in entry_re.finditer(text):
        zone_key = m.group(1)
        if zone_key not in _ZONE_DISPLAY:
            continue
        fields = {k: int(v) if '.' not in v else float(v)
                  for k, v in field_re.findall(m.group(2))}
        if 'cost' not in fields:
            continue
        results.append({
            'zone':    zone_key,
            'display': _ZONE_DISPLAY[zone_key],
            'cost':    fields.get('cost', 0),
            'infamy':  fields.get('infamy', 0),
            'gil':     fields.get('gil', 0),
            'level':   fields.get('level', 0),
            'maxHP':   fields.get('maxHP', 0),
        })
    return results


def _group_tiers(zones: list[dict]) -> list[dict]:
    """Collapse zones into per-tier dicts, preserving order by ascending cost."""
    tiers: dict[int, dict] = {}
    for z in zones:
        cost = z['cost']
        if cost not in tiers:
            # Infer tier name from cost
            name = {200: 'Visions', 350: 'Scars', 500: 'Heroes'}.get(cost, f'{cost}mk')
            tiers[cost] = {
                'name':   name,
                'cost':   cost,
                'level':  z['level'],
                'maxHP':  z['maxHP'],
                'infamy': z['infamy'],
                'gil':    z['gil'],
                'zones':  [],
            }
        tiers[cost]['zones'].append(z['display'])
    return [tiers[k] for k in sorted(tiers)]


# ---------------------------------------------------------------------------
# Renderers
# ---------------------------------------------------------------------------


def _render_tiers(tiers: list[dict]) -> str:
    rows = ['| Tier | Zones | Mark Cost | Level | HP |', '|---|---|---|---|---|']
    for t in tiers:
        zones_str = ', '.join(t['zones'])
        hp_str    = f"{t['maxHP']:,}"
        rows.append(
            f"| **{t['name']}** | {zones_str} | {t['cost']} marks | {t['level']} | {hp_str} |"
        )
    return '\n'.join(rows)


def _render_rewards(tiers: list[dict]) -> str:
    max_mult = _PARTY_MULT * _TRUST_MULT

    lines: list[str] = [
        '### Base rewards by tier',
        '',
        '| Tier | Infamy | Gil |',
        '|---|---|---|',
    ]
    for t in tiers:
        lines.append(f"| {t['name']} | {t['infamy']} | {t['gil']:,} |")

    lines += [
        '',
        '### Multipliers',
        '',
        'Two bonuses can stack on top of the base reward:',
        '',
        '| Condition | Multiplier |',
        '|---|---|',
        f'| **2 or more real players** in party | ×{_PARTY_MULT:.1f} |',
        f'| **No trusts** in party | ×{_TRUST_MULT:.1f} |',
        '',
        f'These multiply together, so a full party of real players with no trusts earns **×{max_mult:.1f}**.',
        '',
        '### Full reward table',
        '',
    ]

    scenarios = [
        ('Solo, with trusts',   1.0,          1.0),
        ('Solo, no trusts',     1.0,          _TRUST_MULT),
        ('Party, with trusts',  _PARTY_MULT,  1.0),
        ('Party, no trusts',    _PARTY_MULT,  _TRUST_MULT),
    ]
    for t in tiers:
        lines.append(f'=== "{t["name"]}"')
        lines.append('')
        lines.append('    | Scenario | Mult | Infamy | Gil |')
        lines.append('    |---|---|---|---|')
        for label, pm, tm in scenarios:
            mult   = pm * tm
            infamy = int(t['infamy'] * mult)
            gil    = int(t['gil']    * mult)
            lines.append(f'    | {label} | ×{mult:.1f} | {infamy} | {gil:,} |')
        lines.append('')

    return '\n'.join(lines).rstrip()


# ---------------------------------------------------------------------------
# Infamy "reference points" — what your Infamy buys and how many Heroes kills
# it takes. Every number is derived: per-kill from the reward config (Heroes
# base x the full party/no-trust multiplier), item costs from the live Infamy
# Vendor catalog. So it can never drift from a retune of either the rewards or
# the vendor prices. The full per-item catalog lives on the Gear Vendors page
# (infamy_npc.py) — this is just the headline economics, not a duplicate list.
# ---------------------------------------------------------------------------

_INFAMY_CATALOG = "modules/custom/lua/infamy_vendor_catalog.lua"
# id -> 'Category/Sub' rows in catalog.itemTypeMap (e.g. [21621] = 'Weapons/Sword').
_TYPEMAP_RE = re.compile(r"\[(\d+)\]\s*=\s*'([^']+)'")


def _kills(cost: int, per_kill: int) -> str:
    n = max(1, math.ceil(cost / per_kill))
    return f"{n} kill" if n == 1 else f"{n} kills"


def _render_infamy_reference(repo_root: Path, heroes_infamy: int) -> str | None:
    # Import here (not at module load) to avoid any import-order coupling with
    # the dungeons generator, whose vendor-item parser we reuse verbatim.
    from tools.docgen.generators import dungeons

    src = resolve_source(repo_root, _INFAMY_CATALOG)
    if src is None or not heroes_infamy:
        return None
    text = src.read_text(encoding="utf-8", errors="replace")
    items = (dungeons._extract_vendor_items_block(text, "catalog.vendorItems")
             + dungeons._extract_vendor_items_block(text, "catalog.vendorItemsAuto"))
    costs = [int(it["cost"]) for it in items if it.get("cost")]
    if not costs:
        return None

    tmap = dict(_TYPEMAP_RE.findall(text))
    # Canonical endgame-weapon price = the most common cost among vendor weapons
    # priced >= 1,000 Infamy (the relic/mythic/aeonic tier, above the cheap
    # top-5 leveling weapons). Ties resolve to the lower price.
    weapon_costs = [int(it["cost"]) for it in items
                    if it.get("cost")
                    and tmap.get(str(it.get("id")), "").startswith("Weapons")
                    and int(it["cost"]) >= 1000]
    if weapon_costs:
        top = Counter(weapon_costs).most_common()
        top.sort(key=lambda kv: (-kv[1], kv[0]))
        weapon_std = top[0][0]
    else:
        weapon_std = max(costs)

    per_kill = int(round(heroes_infamy * _PARTY_MULT * _TRUST_MULT))
    entry, dearest = min(costs), max(costs)

    lines = [
        "Infamy is spent at the **Infamy Vendor** in {{npc:infamy_vendor}}. The full "
        "catalog — accessories, best-in-slot armor, and Relic / Mythic / Aeonic weapons — "
        "is listed with exact prices on the "
        "[Gear Vendors](../progression/gear-vendors.md#infamy-vendor) page. A few reference "
        "points, priced against the top **Heroes** payout:",
        "",
        "| Reward | Infamy | Heroes kills _(party, no trusts — ×3.0)_ |",
        "|---|---:|---:|",
        f"| Cheapest item | {entry:,} | {_kills(entry, per_kill)} |",
        f"| Standard endgame weapon _(Relic / Mythic / Aeonic)_ | {weapon_std:,} "
        f"| {_kills(weapon_std, per_kill)} |",
        f"| Most expensive item | {dearest:,} | {_kills(dearest, per_kill)} |",
        "",
        f"A full party clearing **Heroes** NMs without trusts earns **{per_kill} Infamy "
        f"per kill** (the ×3.0 rate from the reward table above) — so a standard endgame "
        f"weapon works out to roughly **{_kills(weapon_std, per_kill)}**.",
    ]
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------


def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, "modules/custom/lua/AbysseaMarks.lua")
    if src is None:
        print("[abyssea_nms] skip: AbysseaMarks.lua not found")
        return

    page = docs_dir / "endgame" / "abyssea-nms.md"
    if not page.exists():
        print(f"[abyssea_nms] skip: {page} not found")
        return

    text  = src.read_text(encoding="utf-8", errors="replace")
    zones = _parse_zone_config(text)
    if not zones:
        print("[abyssea_nms] skip: no zone entries found in AbysseaMarks.lua")
        return

    tiers = _group_tiers(zones)

    for marker_id, content in [
        ("abyssea-tiers",   _render_tiers(tiers)),
        ("abyssea-rewards", _render_rewards(tiers)),
    ]:
        wrote  = write_between_markers(page, marker_id, content)
        status = "written" if wrote else f"MARKER NOT FOUND: {marker_id}"
        print(f"[abyssea_nms] {marker_id}: {status}")

    # Infamy "reference points" economics — derived from the Heroes reward and
    # the live Infamy Vendor catalog (see _render_infamy_reference). Uses the
    # highest-cost tier's infamy as "Heroes" so it tracks a tier rename/retune.
    heroes_infamy = max((t["infamy"] for t in tiers), default=0)
    ref = _render_infamy_reference(repo_root, heroes_infamy)
    if ref:
        wrote = write_between_markers(page, "abyssea-infamy-costs", ref)
        print(f"[abyssea_nms] abyssea-infamy-costs: {'written' if wrote else 'MARKER NOT FOUND'}")
    else:
        print("[abyssea_nms] abyssea-infamy-costs: skip (no catalog/heroes infamy)")

    # (Superior Lv5 weapon drops removed 2026-07-12 — owner pulled the
    # any-Abyssea-mob Su5 system pending a new home for the 22 weapons.)
