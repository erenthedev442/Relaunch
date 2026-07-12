"""Sync docs/endgame/affinity-nms.md with augment_affinity_catalog.lua.

Parses the registering affinity NM rows AND the registration config
(multiplier, HL rank requirement, Hunt Mark cost) so re-ordering/renaming NMs
or retuning the gate auto-updates the docs page — no hand-edited numbers to
drift. The repop delay is read from affinity_nm_autopop.lua (RESPAWN_SECONDS)
for the same reason.

Markers written:
  affinity-overview     — "What affinities do" (roll twice, keep the better;
                          affinityMult is legacy and deliberately not rendered)
  affinity-how-it-works — the 5-step flow + registration cost (rank + marks).
                          The trophy goes to the whole in-zone party/alliance,
                          NOT just the killer (augment_affinity_grants.lua drops
                          the isKiller gate), so no killing-blow text is emitted.
  affinity-nm-roster    — one row per registering NM: name, zone, trophy,
                          augment category (11 since the 2026-07-06 rework)
  affinity-difficulty   — HP multiplier + stat-boost table from NM_HP_MULT /
                          NM_MODS in affinity_nm_autopop.lua
"""
from __future__ import annotations

import re
from pathlib import Path

from tools.docgen._paths import resolve_source
from tools.docgen._markers import write_between_markers

# affinityRankReq is a plain Hunting League tier number; these are its display
# names (from hunting_league_catalog.lua "Rank N - Name"). Sourcing the NUMBER
# from the catalog means a retune of the gate (e.g. 3 -> 4) re-labels the docs.
_RANK_NAMES = {
    1: "I (Initiate)",
    2: "II (Hunter)",
    3: "III (Elite)",
    4: "IV (Champion)",
    5: "V (Legend)",
}


def _qstr(text: str, key: str) -> str | None:
    """Extract value of `key='...'` or `key="..."` from a Lua table string."""
    m = re.search(r'\b' + re.escape(key) + r"""=(?:'([^']*)'|"([^"]*)")""", text)
    if not m:
        return None
    return m.group(1) if m.group(1) is not None else m.group(2)


def _num(text: str, key: str) -> float | None:
    """Extract `catalog.<key> = N` (int or float) from the Lua file."""
    m = re.search(r'\bcatalog\.' + re.escape(key) + r'\s*=\s*([0-9]+(?:\.[0-9]+)?)', text)
    return float(m.group(1)) if m else None


def _parse(text: str) -> list[dict]:
    rows = []
    for line in text.splitlines():
        line = line.strip()
        if not line.startswith('{ cat='):
            continue
        cat_m = re.search(r'cat=(\d+)', line)
        if not cat_m:
            continue

        label   = _qstr(line, 'label')
        nm_raw  = _qstr(line, 'nm')
        nm_zone = _qstr(line, 'nmZone')

        # trophy name is inside trophy={...}; extract that sub-string first
        trophy_blk_m = re.search(r'trophy=\{([^}]*)\}', line)
        trophy_blk   = trophy_blk_m.group(1) if trophy_blk_m else ''
        trophy_name  = _qstr(trophy_blk, 'name')

        if not all([label, nm_raw, nm_zone, trophy_name]):
            continue

        nm_display = nm_raw.replace('_', ' ')
        rows.append({
            'cat':    int(cat_m.group(1)),
            'nm':     nm_display,
            'zone':   nm_zone,
            'trophy': trophy_name,
            'label':  label,
        })

    rows.sort(key=lambda r: r['cat'])
    return rows


# xi.mod.* -> (display label, formatter), in render order. HASTE_GEAR is
# engine units (1/10 of a percent); the percent-flagged mods are plain %.
_MOD_DISPLAY = [
    ('ATT',           'Attack',            lambda v: f'+{v:,}'),
    ('ACC',           'Accuracy',          lambda v: f'+{v:,}'),
    ('DEF',           'Defense',           lambda v: f'+{v:,}'),
    ('EVA',           'Evasion',           lambda v: f'+{v:,}'),
    ('MATT',          'Magic Attack',      lambda v: f'+{v:,}'),
    ('MDEF',          'Magic Defense',     lambda v: f'+{v:,}'),
    ('STR',           'STR',               lambda v: f'+{v:,}'),
    ('DEX',           'DEX',               lambda v: f'+{v:,}'),
    ('HASTE_GEAR',    'Haste',             lambda v: f'~+{v / 10:.0f}%'),
    ('DOUBLE_ATTACK', 'Double Attack',     lambda v: f'+{v}%'),
    ('CRITHITRATE',   'Critical Hit Rate', lambda v: f'+{v}%'),
    ('STORETP',       'Store TP',          lambda v: f'+{v}'),
]


def _render_difficulty(hp_mult: float | None, mods: dict) -> str:
    lines = [
        "These NMs are **stat-boosted far beyond their retail versions**. Treat every "
        "Affinity NM as a party-level encounter unless you are heavily geared:",
        "",
        '| Boost | Value |',
        '|---|---:|',
    ]
    if hp_mult and hp_mult > 1.0:
        lines.append(f'| HP | ×{hp_mult:g} |')
    rendered = set()
    for key, label, fmt in _MOD_DISPLAY:
        if key in mods:
            lines.append(f'| {label} | {fmt(mods[key])} |')
            rendered.add(key)
    # Anything tuned in that this table doesn't know yet: emit raw so a new
    # mod is never silently dropped from the player-facing block.
    for key in sorted(k for k in mods if k not in rendered):
        lines.append(f'| {key} | +{mods[key]:,} |')
    return '\n'.join(lines)


def _render_overview() -> str:
    # affinityMult in the catalog is LEGACY -- the live Augment Moogle path
    # rolls a registered-category augment TWICE and keeps the better result
    # (Augment_Moogle.lua), so no multiplier number is emitted here.
    return (
        "**What affinities do:** once registered, every augment roll whose stat falls "
        "in a registered category is **rolled twice and the better result kept** — a "
        "straight upgrade to both your average and your top-end rolls."
    )


def _render_how_it_works(rank_req: int, mark_cost: int, respawn: int) -> str:
    rank_name = _RANK_NAMES.get(rank_req, f"{rank_req}")
    return "\n".join([
        f"1. **Find the NM in its zone.** Every Affinity NM is permanently up — it "
        f"repops about {respawn} seconds after each kill, no pop item, no window. "
        f"Navigate to the zone listed in the table below and look for the NM.",
        "",
        "2. **Kill it.** The trophy is granted straight to **everyone in your party or "
        "alliance who is in the zone** — it does not drop on the floor, and it no longer "
        "matters who lands the killing blow. Keep a free inventory slot: any member whose "
        "inventory is full is warned and skipped, so make room and defeat it again.",
        "",
        "3. **Take the trophy to the Augment Sage** at {{npc:augment_sage}} (`!hub`).",
        "",
        f"4. **Register the affinity.** Each registration costs **Hunting League Rank "
        f"{rank_name}** or higher and **{mark_cost:,} Hunt Marks**.",
        "",
        "5. **Augment.** Affinities apply automatically through the Augment Moogle. Any "
        "roll in a registered category is rolled twice and the better result kept.",
    ])


def _render_roster(rows: list[dict]) -> str:
    lines = [
        '| NM | Zone | Trophy Item | Augment Category |',
        '|---|---|---|---|',
    ]
    for r in rows:
        lines.append(f"| {r['nm']} | {r['zone']} | {r['trophy']} | {r['label']} |")
    return '\n'.join(lines)


def generate(repo_root: Path, docs_dir: Path) -> None:
    src = resolve_source(repo_root, 'modules/custom/lua/augment_affinity_catalog.lua')
    if src is None:
        print('[affinity_nms] skip: augment_affinity_catalog.lua not found')
        return

    text = src.read_text(encoding='utf-8', errors='replace')
    rows = _parse(text)

    rank_req  = int(_num(text, 'affinityRankReq')  or 3)
    mark_cost = int(_num(text, 'affinityMarkCost') or 1000)

    # Repop delay + difficulty numbers come from the autopop module so a
    # respawn or stat-block retune updates the docs.
    respawn = 30
    hp_mult: float | None = None
    mods: dict = {}
    autopop = resolve_source(repo_root, 'modules/custom/lua/affinity_nm_autopop.lua')
    if autopop is not None:
        ap_text = autopop.read_text(encoding='utf-8', errors='replace')
        m = re.search(r'\bRESPAWN_SECONDS\s*=\s*(\d+)', ap_text)
        if m:
            respawn = int(m.group(1))
        m = re.search(r'\bNM_HP_MULT\s*=\s*([0-9]+(?:\.[0-9]+)?)', ap_text)
        if m:
            hp_mult = float(m.group(1))
        for mod_m in re.finditer(r'\[xi\.mod\.(\w+)\]\s*=\s*(\d+)', ap_text):
            mods[mod_m.group(1)] = int(mod_m.group(2))

    page = docs_dir / 'endgame' / 'affinity-nms.md'
    if not page.exists():
        print(f'[affinity_nms] skip: {page} not found')
        return

    blocks = [
        ('affinity-overview',     _render_overview()),
        ('affinity-how-it-works', _render_how_it_works(rank_req, mark_cost, respawn)),
        ('affinity-nm-roster',    _render_roster(rows)),
    ]
    # Fail-closed: if the difficulty numbers didn't parse, keep the block's
    # previous content rather than publishing an empty table.
    if mods or hp_mult:
        blocks.append(('affinity-difficulty', _render_difficulty(hp_mult, mods)))
    else:
        print('[affinity_nms] warn: no NM_MODS/NM_HP_MULT parsed — '
              'affinity-difficulty keeps previous content')

    written = 0
    for marker_id, content in blocks:
        if write_between_markers(page, marker_id, content):
            written += 1
        else:
            print(f'[affinity_nms] marker not found: {marker_id}')
    print(f'[affinity_nms] {written}/{len(blocks)} markers written '
          f'(rows={len(rows)}, rank={rank_req}, marks={mark_cost}, respawn={respawn}s, '
          f'hp_mult={hp_mult}, mods={len(mods)})')
