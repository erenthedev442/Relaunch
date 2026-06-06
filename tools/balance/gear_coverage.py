"""Generate a gear-coverage matrix for balancing analysis.

For each equipment slot, walks the three custom gear catalogs
(gear_progression / armor / reforge), joins with `item_mods` +
`item_equipment` from the live DB, classifies each item into one of
four scenarios (TP / WS / Magic / Tank) via mod scoring, and emits
markdown showing overlaps and gaps per (slot, job).

Usage:
    python tools/balance/gear_coverage.py
Output:
    docs/admin/gear-coverage/<slot>.md
    docs/admin/gear-coverage/index.md
"""
from __future__ import annotations

import re
import sys
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT))

from tools.docgen._db import connect  # noqa: E402
from tools.docgen._paths import resolve_source  # noqa: E402


# ---------------------------------------------------------------------------
# Data shapes
# ---------------------------------------------------------------------------

@dataclass
class GearOption:
    """One row in the matrix — a gear piece available from one system."""
    source:     str                                  # 'Reforge AF+3', 'HL T3', etc.
    item_id:    int
    item_name:  str                                  # from item_basic
    cost:       Optional[str]                        # e.g., '1000 AF Marks' (None if unknown)
    jobs:       str                                  # e.g., 'PLD/RDM/BLU' or 'All'
    slot_mask:  int                                  # raw from item_equipment.slot
    mods:       list[tuple[int, int]] = field(default_factory=list)   # [(modId, value), ...]
    scenarios:  dict[str, float] = field(default_factory=dict)        # {'TP': 12.3, 'WS': 8.1, ...}
    primary:    str = ''                             # winning scenario


# Slot bitmask values (from src/map/items/item_equipment.h - SlotID enum).
# An item_equipment.slot column holds (1 << slotId) for each slot it can equip in.
SLOT_BITS = {
    'main':   1 << 0,
    'sub':    1 << 1,
    'range':  1 << 2,
    'ammo':   1 << 3,
    'head':   1 << 4,
    'body':   1 << 5,
    'hands':  1 << 6,
    'legs':   1 << 7,
    'feet':   1 << 8,
    'neck':   1 << 9,
    'waist':  1 << 10,
    'ear':    (1 << 11) | (1 << 12),
    'ring':   (1 << 13) | (1 << 14),
    'back':   1 << 15,
}
SLOTS_IN_ORDER = ['main', 'sub', 'range', 'head', 'body', 'hands', 'legs', 'feet',
                  'neck', 'waist', 'ear', 'ring', 'back']


# ---------------------------------------------------------------------------
# Scenario weights — defined by mod NAME (resolved to IDs from mod.lua at
# runtime). Earlier versions hardcoded IDs and silently misclassified —
# HASTE_GEAR was at ID 379 in my head but is actually 384, and the slot
# at 379 is STUNRES. Name-driven mapping kills that whole class of bug.
# ---------------------------------------------------------------------------

# Per-WS damage mods occupy IDs 570..825 (WEAPONSKILL_DAMAGE_BASE + wsID).
WEAPONSKILL_DMG_BASE = 570
PER_WS_DMG_WEIGHT = 4.0


# For mods where NEGATIVE values are "good for the player" (the DMG-taken
# family: -1000 = +10% damage reduction = a tank stat), we use a NEGATIVE
# weight. Negative × negative = positive score, the desired direction.
#
# HASTE_GEAR is scaled in 10000ths (10000 = 100% haste, capped ~2500 = 25%).
# Weight kept small so a typical +1600 (16%) maxes ~8 score.

SCENARIO_WEIGHTS_BY_NAME: dict[str, dict[str, float]] = {
    'TP': {
        'HASTE_GEAR':    0.005,
        'DUAL_WIELD':    5.0,
        'DOUBLE_ATTACK': 4.0,
        'TRIPLE_ATTACK': 6.0,
        'STORETP':       1.5,
        'SUBTLE_BLOW':   2.0,
        'COUNTER':       3.0,
        'CRITHITRATE':   2.0,
        'ACC':           0.25,
        'ATT':           0.10,
        'STR':           0.3,
        'DEX':           0.3,
        'VIT':           0.1,
        'AGI':           0.1,
    },
    'WS': {
        'STR':           1.0,
        'DEX':           1.0,
        'VIT':           0.8,
        'AGI':           0.8,
        'INT':           0.8,
        'MND':           0.8,
        'CHR':           0.6,
        'ALL_WSDMG_ALL_HITS':  6.0,
        'ALL_WSDMG_FIRST_HIT': 3.5,
        'CRITHITRATE':         3.0,
        'SKILLCHAINDMG':       2.0,
        'WS_STR_BONUS': 4.0,
        'WS_DEX_BONUS': 4.0,
        'WS_VIT_BONUS': 4.0,
        'WS_AGI_BONUS': 4.0,
        'WS_INT_BONUS': 4.0,
        'WS_MND_BONUS': 4.0,
        'WS_CHR_BONUS': 4.0,
    },
    'Magic': {
        'MATT':           5.0,
        'MACC':           4.0,
        'MEVA':           1.0,
        'INT':            1.2,
        'MND':            1.2,
        'CURE_POTENCY':   4.0,
        'CURE_POTENCY_RCVD': 2.0,
        'FASTCAST':       3.0,
        'UFASTCAST':      3.0,
        'SPELLINTERRUPT': -0.5,    # lower is better for the caster
        'MAGIC_DAMAGE':   0.4,
        # Elemental MAB.
        'FIRE_MAB':       1.5,
        'ICE_MAB':        1.5,
        'WIND_MAB':       1.5,
        'EARTH_MAB':      1.5,
        'THUNDER_MAB':    1.5,
        'WATER_MAB':      1.5,
        'LIGHT_MAB':      1.5,
        'DARK_MAB':       1.5,
    },
    'Tank': {
        'DEF':           0.35,
        'HP':            0.2,
        # Damage-taken mods: NEGATIVE weight, since the stored value is
        # negative when "+10% damage reduction" is the intent.
        'DMG':          -0.06,
        'DMGPHYS':      -0.06,
        'DMGMAGIC':     -0.06,
        'DMGBREATH':    -0.04,
        'DMGRANGE':     -0.04,
        'UDMGPHYS':     -0.06,
        'UDMGMAGIC':    -0.06,
        'UDMGBREATH':   -0.04,
        'UDMGRANGE':    -0.04,
        'ENMITY':        3.0,
        'ENMITY_LOSS_REDUCTION': 2.5,
        'SLASH_DEF':     1.0,
        'PIERCE_DEF':    1.0,
        'COUNTER':       2.0,
        'VIT':           0.4,
    },
}


def _resolve_weights(mod_name_to_id: dict[str, int]) -> dict[str, dict[int, float]]:
    """Resolve NAME-keyed weights into ID-keyed weights via the mod.lua lookup.
    Names that don't resolve are dropped with a single warning line."""
    out: dict[str, dict[int, float]] = {}
    missing: set[str] = set()
    for scenario, named in SCENARIO_WEIGHTS_BY_NAME.items():
        bucket: dict[int, float] = {}
        for name, weight in named.items():
            mod_id = mod_name_to_id.get(name)
            if mod_id is None:
                missing.add(name)
                continue
            bucket[mod_id] = weight
        out[scenario] = bucket
    if missing:
        print(f'  warn: {len(missing)} mod names dropped (not found in mod.lua): '
              f'{sorted(missing)[:5]}{"..." if len(missing) > 5 else ""}')
    return out


# Populated by main(); classify() reads from here.
_RESOLVED_WEIGHTS: dict[str, dict[int, float]] = {}


def _ws_dmg_range():
    """All per-WS damage mod IDs (570 + 0..255)."""
    return range(WEAPONSKILL_DMG_BASE, WEAPONSKILL_DMG_BASE + 256)


def classify(option: GearOption) -> None:
    """Compute scenarios{} and primary on the option."""
    scores = {sc: 0.0 for sc in _RESOLVED_WEIGHTS}
    for mod_id, value in option.mods:
        for sc, weights in _RESOLVED_WEIGHTS.items():
            w = weights.get(mod_id)
            if w is not None:
                scores[sc] += w * value
        if mod_id in _ws_dmg_range():
            scores['WS'] += PER_WS_DMG_WEIGHT * value

    option.scenarios = scores
    if all(s <= 0 for s in scores.values()):
        option.primary = '—'
        return

    top = max(scores, key=lambda k: scores[k])
    runner_up = sorted(scores.values(), reverse=True)[1] if len(scores) > 1 else 0.0
    if runner_up > 0 and scores[top] > 0 and runner_up / scores[top] > 0.7:
        runners = [k for k, v in scores.items() if k != top and v > 0 and v / scores[top] > 0.7]
        option.primary = f'{top}/{runners[0]}'
    else:
        option.primary = top


# ---------------------------------------------------------------------------
# Catalog parsing
# ---------------------------------------------------------------------------

def parse_item_enum(repo_root: Path) -> dict[str, int]:
    """Build `{ENUM_NAME: id}` from scripts/enum/item.lua."""
    path = resolve_source(repo_root, 'scripts/enum/item.lua')
    if path is None:
        return {}
    text = path.read_text(encoding='utf-8', errors='replace')
    out: dict[str, int] = {}
    # Match lines like  `    ALMACE_119_III = 20689,`
    for m in re.finditer(r'^\s*([A-Z][A-Z0-9_]+)\s*=\s*(\d+)\s*,?\s*$', text, re.MULTILINE):
        out[m.group(1)] = int(m.group(2))
    return out


_GP_TABLE_INSERT_RE = re.compile(
    r"table\.insert\(\s*(\w+)\s*,\s*\{\s*id\s*=\s*xi\.item\.([A-Z][A-Z0-9_]+)\s*,"
    r"\s*name\s*=\s*'([^']+)'\s*,"
    r"\s*cost\s*=\s*(\d+)\s*,"
    r"\s*jobs\s*=\s*'([^']+)'"
)
_GP_LOCAL_CAT_RE = re.compile(
    r"local\s+(\w+)\s*=\s*cat\(catalog\.(\w+)\.(\w+),\s*'([^']+)'\)"
)


def parse_gear_progression(repo_root: Path, item_enum: dict[str, int]) -> list[GearOption]:
    """Parse gear_progression_catalog.lua → top-tier weapons (REMA III / Aeonics)."""
    path = resolve_source(repo_root, 'modules/custom/lua/gear_progression_catalog.lua')
    if path is None:
        return []
    text = path.read_text(encoding='utf-8', errors='replace')

    # Map local-var name -> (tier, category)  e.g.  swords -> (gold, Swords)
    local_lookup: dict[str, tuple[str, str, str]] = {}
    for m in _GP_LOCAL_CAT_RE.finditer(text):
        local_lookup[m.group(1)] = (m.group(2), m.group(3), m.group(4))

    out: list[GearOption] = []
    for m in _GP_TABLE_INSERT_RE.finditer(text):
        local_name, item_sym, name, cost, jobs = m.groups()
        item_id = item_enum.get(item_sym)
        if not item_id:
            continue
        tier_cat = local_lookup.get(local_name)
        tier_label = f'Gold vendor ({tier_cat[2]})' if tier_cat else 'Gold vendor'
        out.append(GearOption(
            source    = tier_label,
            item_id   = item_id,
            item_name = name,
            cost      = f'{cost} gold marks',
            jobs      = jobs,
            slot_mask = 0,    # filled in later from DB
        ))
    return out


_ARMOR_LOCAL_RE = re.compile(r"local\s+(\w+)\s*=\s*catalog\.(\w+)\s*$", re.MULTILINE)
_ARMOR_INSERT_RE = re.compile(
    r"table\.insert\(\s*(\w+)\.(\w+)\s*,\s*\{\s*id\s*=\s*(\d+)\s*,"
    r"\s*name\s*=\s*\"([^\"]+)\"\s*,"
    r"\s*cost\s*=\s*(\d+)\s*,"
    r"\s*jobs\s*=\s*'([^']+)'\s*\}\)"
    r"(?:\s*--\s*([A-Z]+)\s+score\s+(\d+))?"
)


def parse_armor(repo_root: Path) -> list[GearOption]:
    """Parse armor_catalog.lua → HL Armor NPC (5 tiers x 5 slots)."""
    path = resolve_source(repo_root, 'modules/custom/lua/armor_catalog.lua')
    if path is None:
        return []
    text = path.read_text(encoding='utf-8', errors='replace')

    local_lookup: dict[str, str] = {m.group(1): m.group(2) for m in _ARMOR_LOCAL_RE.finditer(text)}

    out: list[GearOption] = []
    for m in _ARMOR_INSERT_RE.finditer(text):
        local_name, slot, item_id, name, cost, jobs, role_tag, _score = m.groups()
        tier = local_lookup.get(local_name, '?')
        out.append(GearOption(
            source    = f'HL {tier.capitalize()} {slot}',
            item_id   = int(item_id),
            item_name = name,
            cost      = f'{cost} {tier} seals',
            jobs      = jobs,
            slot_mask = 0,
        ))
    return out


_REFORGE_JOB_BLOCK_RE = re.compile(
    r"catalog\.pieces\[xi\.job\.(\w+)\]\s*=\s*\{(.*?)\n\}\s*\n", re.DOTALL
)
_REFORGE_SET_RE = re.compile(
    r"\b(af|relic|empy)\s*=\s*(?:--[^\n]*\n)?\s*\{(.*?)\n\s*\}", re.DOTALL
)
_REFORGE_SLOT_RE = re.compile(
    r"\b(head|body|hands|legs|feet)\s*=\s*\{\s*([\d,\s]+)\s*\}"
)
SET_LABELS = {'af': 'AF', 'relic': 'Relic', 'empy': 'Empyrean'}


def parse_reforge(repo_root: Path) -> list[GearOption]:
    """Parse reforge_catalog.lua → AF/Relic/Empy +3 (taking the +3 tier, last
    item ID in each 4-element slot array)."""
    path = resolve_source(repo_root, 'modules/custom/lua/reforge_catalog.lua')
    if path is None:
        return []
    text = path.read_text(encoding='utf-8', errors='replace')

    out: list[GearOption] = []
    for job_match in _REFORGE_JOB_BLOCK_RE.finditer(text):
        job = job_match.group(1)
        body = job_match.group(2)
        for set_match in _REFORGE_SET_RE.finditer(body):
            set_key = set_match.group(1)
            set_body = set_match.group(2)
            for slot_match in _REFORGE_SLOT_RE.finditer(set_body):
                slot = slot_match.group(1)
                ids = [int(x.strip()) for x in slot_match.group(2).split(',') if x.strip()]
                if len(ids) < 4:
                    continue
                # We score the +3 tier (the last id).
                plus3_id = ids[3]
                out.append(GearOption(
                    source    = f'Reforge {SET_LABELS[set_key]}+3',
                    item_id   = plus3_id,
                    item_name = '',                  # filled from DB
                    cost      = None,
                    jobs      = job,
                    slot_mask = 0,
                ))
    return out


# ---------------------------------------------------------------------------
# DB enrichment
# ---------------------------------------------------------------------------

def enrich_from_db(options: list[GearOption], conn) -> None:
    """Populate item_name, slot_mask, and mods on each option from the DB."""
    if not options:
        return
    cur = conn.cursor()
    ids = list({o.item_id for o in options})

    # item_basic (name)
    cur.execute(
        f"SELECT itemId, name FROM item_basic WHERE itemId IN ({','.join(['%s'] * len(ids))})",
        ids,
    )
    name_by_id = {row[0]: row[1] for row in cur.fetchall()}

    # item_equipment (slot mask + jobs mask + reqLvl)
    cur.execute(
        f"SELECT itemId, slot, jobs, `level` FROM item_equipment "
        f"WHERE itemId IN ({','.join(['%s'] * len(ids))})",
        ids,
    )
    equip_by_id = {row[0]: (row[1], row[2], row[3]) for row in cur.fetchall()}

    # item_mods (modifier list)
    cur.execute(
        f"SELECT itemId, modId, value FROM item_mods "
        f"WHERE itemId IN ({','.join(['%s'] * len(ids))}) ORDER BY itemId, modId",
        ids,
    )
    mods_by_id: dict[int, list[tuple[int, int]]] = defaultdict(list)
    for item_id, mod_id, value in cur.fetchall():
        mods_by_id[item_id].append((mod_id, value))

    for o in options:
        if not o.item_name:
            o.item_name = name_by_id.get(o.item_id, f'item {o.item_id}')
        slot_jobs = equip_by_id.get(o.item_id)
        if slot_jobs:
            o.slot_mask = slot_jobs[0]
        o.mods = mods_by_id.get(o.item_id, [])
        classify(o)


# ---------------------------------------------------------------------------
# Mod label lookup (so the output reads as "DEX+50" not "9: 50")
# ---------------------------------------------------------------------------

_MOD_NAME_RE = re.compile(r"^\s*([A-Z][A-Z0-9_]*)\s*=\s*(\d+)\s*,", re.MULTILINE)


def load_mod_names(repo_root: Path) -> dict[int, str]:
    """Build modId -> display name from scripts/enum/mod.lua."""
    path = resolve_source(repo_root, 'scripts/enum/mod.lua')
    if path is None:
        return {}
    text = path.read_text(encoding='utf-8', errors='replace')
    out: dict[int, str] = {}
    for m in _MOD_NAME_RE.finditer(text):
        out[int(m.group(2))] = m.group(1)
    return out


def fmt_mods(mods: list[tuple[int, int]], names: dict[int, str], top_n: int = 6) -> str:
    """Render the N most 'interesting' mods. Sort key is abs(value) * the
    max |weight| this mod gets across all scenarios — so high-impact mods
    (DW, haste, MAB, DMG-taken) surface even when their raw value is small.
    Falls back to abs(value) when no weight is known."""
    if not mods:
        return '—'

    def impact(mv):
        mid, val = mv
        w = 0.0
        for sc_weights in _RESOLVED_WEIGHTS.values():
            cw = sc_weights.get(mid)
            if cw is not None and abs(cw) > w:
                w = abs(cw)
        if w == 0:
            w = 0.1
        return abs(val) * w

    ranked = sorted(mods, key=impact, reverse=True)[:top_n]
    parts = []
    for mid, val in ranked:
        nm = names.get(mid, f'mod{mid}')
        if WEAPONSKILL_DMG_BASE <= mid <= WEAPONSKILL_DMG_BASE + 255:
            nm = f'WS#{mid - WEAPONSKILL_DMG_BASE}_DMG'
        sign = '+' if val >= 0 else ''
        parts.append(f'{nm}{sign}{val}')
    return ', '.join(parts)


# ---------------------------------------------------------------------------
# Markdown emission
# ---------------------------------------------------------------------------

OUT_DIR = REPO_ROOT / 'docs' / 'admin' / 'gear-coverage'


def emit_slot(slot: str, options: list[GearOption], mod_names: dict[int, str]) -> None:
    """Write one markdown file showing coverage for the given slot."""
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    rows = [o for o in options if o.slot_mask & SLOT_BITS[slot]]
    if not rows:
        return

    out: list[str] = []
    out.append(f'# Gear Coverage: {slot}\n')
    out.append('> Generated by `tools/balance/gear_coverage.py`. Each row is one '
               'option a player can obtain. The "primary" column is heuristic — '
               'classified from the item\'s mods via `SCENARIO_WEIGHTS`. Take it '
               'as a hint, not gospel.\n')

    # Group by job tag from the catalog (e.g. 'PLD/RDM' or 'WAR' or 'PLD').
    # Items that fit multiple jobs get listed once per job.
    by_job: dict[str, list[GearOption]] = defaultdict(list)
    for o in rows:
        for job in (j.strip() for j in o.jobs.split('/')):
            by_job[job].append(o)

    # Stable job order
    job_order = ['WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK',
                 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'SMN', 'BLU',
                 'COR', 'PUP', 'DNC', 'SCH', 'GEO', 'RUN']
    jobs_present = [j for j in job_order if j in by_job]
    jobs_present += [j for j in sorted(by_job) if j not in job_order]

    for job in jobs_present:
        opts = by_job[job]
        out.append(f'\n## {job}\n')
        out.append('| Source | Item | Primary | TP | WS | Magic | Tank | Cost | Key mods |')
        out.append('|---|---|---|---:|---:|---:|---:|---|---|')
        for o in sorted(opts, key=lambda x: (x.source, -max(x.scenarios.values(), default=0))):
            sc = o.scenarios
            cost = o.cost or '—'
            mods = fmt_mods(o.mods, mod_names, top_n=6)
            out.append(
                f'| {o.source} | {o.item_name} | **{o.primary}** | '
                f'{sc.get("TP", 0):.0f} | {sc.get("WS", 0):.0f} | '
                f'{sc.get("Magic", 0):.0f} | {sc.get("Tank", 0):.0f} | '
                f'{cost} | {mods} |'
            )

        # Coverage roll-up: which scenarios are covered by at least one option,
        # which aren't. Threshold of "covered" is "any option scored that
        # scenario above 5" — keeps trace-amount noise out.
        SCEN = ['TP', 'WS', 'Magic', 'Tank']
        best_by_sc = {sc: max((o.scenarios.get(sc, 0) for o in opts), default=0) for sc in SCEN}
        covered = [sc for sc in SCEN if best_by_sc[sc] >= 5]
        gaps    = [sc for sc in SCEN if best_by_sc[sc] <  5]
        if covered:
            out.append(f'\n**Covered**: {", ".join(covered)}')
        if gaps:
            out.append(f'**Gaps**: {", ".join(gaps)}')

    OUT_DIR.joinpath(f'{slot}.md').write_text('\n'.join(out), encoding='utf-8')


def emit_index(slots_written: list[str]) -> None:
    out = ['# Gear Coverage Matrix (admin)\n',
           '> Per-slot coverage tables generated from the live catalogs +'
           ' `item_mods`. Use these to spot overlaps (multiple sources serving'
           ' the same scenario for the same job) and gaps (no source serving a'
           ' scenario for a job).\n',
           '## Slots\n']
    for s in slots_written:
        out.append(f'- [{s}]({s}.md)')
    OUT_DIR.joinpath('index.md').write_text('\n'.join(out), encoding='utf-8')


# ---------------------------------------------------------------------------
# Entrypoint
# ---------------------------------------------------------------------------

def main() -> int:
    print('Parsing item enum...')
    item_enum = parse_item_enum(REPO_ROOT)
    print(f'  found {len(item_enum)} item enum entries')

    print('Parsing catalogs...')
    options: list[GearOption] = []
    options += parse_gear_progression(REPO_ROOT, item_enum)
    options += parse_armor(REPO_ROOT)
    options += parse_reforge(REPO_ROOT)
    print(f'  found {len(options)} gear options across all catalogs')

    print('Connecting to DB...')
    conn = connect(REPO_ROOT)
    if conn is None:
        print('  DB connection failed — no settings/network.lua reachable, or driver missing')
        return 1

    print('Loading mod names + resolving scenario weights...')
    mod_names = load_mod_names(REPO_ROOT)
    name_to_id = {nm: mid for mid, nm in mod_names.items()}
    global _RESOLVED_WEIGHTS
    _RESOLVED_WEIGHTS = _resolve_weights(name_to_id)
    print(f'  {sum(len(v) for v in _RESOLVED_WEIGHTS.values())} weighted mod entries active')

    print('Enriching from DB...')
    enrich_from_db(options, conn)

    # MVP: emit only `body` slot. Once the format is approved we lift the
    # `if slot == 'body'` guard and emit every entry in SLOTS_IN_ORDER.
    written: list[str] = []
    for slot in SLOTS_IN_ORDER:
        if slot != 'body':
            continue
        emit_slot(slot, options, mod_names)
        written.append(slot)
        print(f'  wrote {OUT_DIR / (slot + ".md")}')

    emit_index(written)
    print(f'Done. {len(written)} slot file(s) written to {OUT_DIR}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
