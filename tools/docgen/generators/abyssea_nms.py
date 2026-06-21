"""Generate Abyssea NM fact-blocks inside docs/endgame/abyssea-nms.md.

Reads: modules/custom/lua/AbysseaMarks.lua

Marker IDs:
  - "abyssea-tiers"    -- Zones & Difficulty tiers table
  - "abyssea-rewards"  -- Base rewards, multipliers, full per-tier reward tabs
"""
from __future__ import annotations

import re
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
    "ABYSSEA_ALTEPA":    "Altepa",
    "ABYSSEA_GRAUBERG":  "Grauberg",
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
# Superior Lv5 (Dynamis Divergence) weapon drops — a SEPARATE system from the NM
# Hunt Marks above, defined in modules/custom/lua/abyssea_su5_drops.lua. Each pool
# row is "<id>, -- <Name> (<Type>, <JOB>)".
# ---------------------------------------------------------------------------

_SU5_CHANCE_RE = re.compile(r'DROP_CHANCE\s*=\s*([\d.]+)')
_SU5_BLOCK_RE  = re.compile(r'SU5_WEAPONS\s*=\s*\{(.*?)\}', re.DOTALL)
_SU5_ROW_RE    = re.compile(r'(\d+)\s*,\s*--\s*(\S[^(]*?)\s*\(\s*([^,]+?)\s*,\s*([^)]+?)\s*\)')


def _render_su5_drops(text: str) -> str | None:
    block = _SU5_BLOCK_RE.search(text)
    if not block:
        return None
    cm  = _SU5_CHANCE_RE.search(text)
    pct = f"{float(cm.group(1)) * 100:g}%" if cm else "5%"
    rows = []
    for m in _SU5_ROW_RE.finditer(block.group(1)):
        iid, name, slot, job = m.group(1), m.group(2).strip(), m.group(3).strip(), m.group(4).strip()
        link = f"[{name}](https://www.ffxiah.com/item/{iid})"
        rows.append((job, link, slot))
    if not rows:
        return None
    rows.sort()
    lines = [
        f"Beyond the NMs, **every regular mob in an Abyssea zone has a {pct} chance on death "
        f"to drop a Superior Lv5 (Dynamis Divergence) weapon** into the treasure pool — a random "
        f"one of the {len(rows)} below (one per job), free for the whole alliance to lot. No "
        f"`???`, pop, Hunt Marks, or trade required; just grind Abyssea mobs.",
        "",
        "| Job | Weapon | Type |",
        "|---|---|---|",
    ]
    for job, link, slot in rows:
        lines.append(f"| {job} | {link} | {slot} |")
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

    # Superior Lv5 (Dynamis Divergence) weapon drops — separate module.
    su5_src = resolve_source(repo_root, "modules/custom/lua/abyssea_su5_drops.lua")
    if su5_src is not None:
        su5 = _render_su5_drops(su5_src.read_text(encoding="utf-8", errors="replace"))
        if su5:
            wrote = write_between_markers(page, "abyssea-su5-drops", su5)
            print(f"[abyssea_nms] abyssea-su5-drops: {'written' if wrote else 'MARKER NOT FOUND'}")
        else:
            print("[abyssea_nms] abyssea-su5-drops: skip (no SU5_WEAPONS parsed)")
