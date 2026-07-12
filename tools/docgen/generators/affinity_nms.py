"""Sync docs/endgame/affinity-nms.md with augment_affinity_catalog.lua.

Parses the registering affinity NM rows AND the registration config
(multiplier, HL rank requirement, Hunt Mark cost) so re-ordering/renaming NMs
or retuning the gate auto-updates the docs page — no hand-edited numbers to
drift. The repop delay is read from affinity_nm_autopop.lua (RESPAWN_SECONDS)
for the same reason.

Markers written:
  affinity-overview     — "What affinities do" (the affinityMult multiplier)
  affinity-how-it-works — the 5-step flow + registration cost (rank + marks).
                          The trophy goes to the whole in-zone party/alliance,
                          NOT just the killer (augment_affinity_grants.lua drops
                          the isKiller gate), so no killing-blow text is emitted.
  affinity-nm-roster    — one row per registering NM: name, zone, trophy,
                          augment category (11 since the 2026-07-06 rework)
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

    # Repop delay comes from the autopop module so a retune updates the docs.
    respawn = 30
    autopop = resolve_source(repo_root, 'modules/custom/lua/affinity_nm_autopop.lua')
    if autopop is not None:
        m = re.search(r'\bRESPAWN_SECONDS\s*=\s*(\d+)', autopop.read_text(encoding='utf-8', errors='replace'))
        if m:
            respawn = int(m.group(1))

    page = docs_dir / 'endgame' / 'affinity-nms.md'
    if not page.exists():
        print(f'[affinity_nms] skip: {page} not found')
        return

    blocks = [
        ('affinity-overview',     _render_overview()),
        ('affinity-how-it-works', _render_how_it_works(rank_req, mark_cost, respawn)),
        ('affinity-nm-roster',    _render_roster(rows)),
    ]
    written = 0
    for marker_id, content in blocks:
        if write_between_markers(page, marker_id, content):
            written += 1
        else:
            print(f'[affinity_nms] marker not found: {marker_id}')
    print(f'[affinity_nms] {written}/{len(blocks)} markers written '
          f'(rows={len(rows)}, rank={rank_req}, marks={mark_cost}, respawn={respawn}s)')
