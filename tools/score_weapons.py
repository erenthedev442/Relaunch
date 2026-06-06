"""Score weapons and bucket into Bronze/Silver/Gold per weapon category.

Sibling to tools/score_armor.py. Reuses the same parsing + role-weight
framework, with two weapon-specific additions:

  1. DPS bonus -- weapon score includes (dmg * 60 / delay) * DPS_WEIGHT.
     A high-DMG slow swing is worth more than a low-DMG fast swing of the
     same iLvl.

  2. Bucketing is per WEAPON CATEGORY (skillType 1..12, 25, 26), not per
     armor slot. The 14 categories map 1:1 to gear_progression_catalog.lua
     entries.

Outputs a patched gear_progression_catalog.lua with bronze/silver/gold
tier blocks regenerated from the live DB scoring. Re-run any time stats
change in the DB or you tune the weights below.
"""
from __future__ import annotations

import re
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(r"D:/server")


# ============================================================================
# SQL parsers (same shape as score_armor.py -- kept inline to avoid coupling)
# ============================================================================
def split_fields(s: str) -> list[str]:
    out, buf, in_q = [], [], False
    for c in s:
        if c == "'":
            in_q = not in_q
            buf.append(c)
        elif c == ',' and not in_q:
            out.append(''.join(buf).strip())
            buf = []
        else:
            buf.append(c)
    out.append(''.join(buf).strip())
    return out


items_base: dict[int, dict] = {}
with (ROOT / 'sql' / 'item_basic.sql').open(encoding='utf-8', errors='replace') as f:
    for line in f:
        m = re.match(r"^INSERT INTO `item_basic` VALUES \((.*)\);$", line)
        if not m:
            continue
        fields = split_fields(m.group(1))
        if len(fields) < 9:
            continue
        try:
            iid = int(fields[0])
        except ValueError:
            continue
        items_base[iid] = {
            'name':    fields[2].strip("'"),
            'is_rare': '@FLAG_RARE' in fields[7],
        }


equip: dict[int, dict] = {}
with (ROOT / 'sql' / 'item_equipment.sql').open(encoding='utf-8', errors='replace') as f:
    for line in f:
        m = re.match(
            r"^INSERT INTO `item_equipment` VALUES "
            r"\((\d+),'([^']+)',(\d+),(\d+),(\d+),(-?\d+),(\d+),(\d+),(\d+),",
            line,
        )
        if not m:
            continue
        equip[int(m.group(1))] = {
            'level':  int(m.group(3)),
            'ilevel': int(m.group(4)),
            'jobs':   int(m.group(5)),
            'slot':   int(m.group(9)),
        }


# Weapon-specific stats: skill type, delay, dmg
weapon_stats: dict[int, dict] = {}
with (ROOT / 'sql' / 'item_weapon.sql').open(encoding='utf-8', errors='replace') as f:
    for line in f:
        # cols: id, name, skill, subskill, ilvl_skill, ilvl_parry, ilvl_macc,
        #       dmgType, hit, delay, dmg, unlock_points
        m = re.match(
            r"^INSERT INTO `item_weapon` VALUES "
            r"\((\d+),'[^']+',(\d+),-?\d+,-?\d+,-?\d+,-?\d+,\d+,\d+,(\d+),(\d+),",
            line,
        )
        if not m:
            continue
        weapon_stats[int(m.group(1))] = {
            'skill': int(m.group(2)),
            'delay': int(m.group(3)),
            'dmg':   int(m.group(4)),
        }


# item_mods loaded in TWO passes mirroring dbtool's load order:
# upstream item_mods.sql then the locally-generated zz_custom_naked_*.sql
# (BG-Wiki stats for ~1400 items not in upstream — Reforge +3/+4, JSE
# +1/+2/+3, etc.). The zz file uses ON DUPLICATE KEY UPDATE; we mirror
# that by overwriting (itemid, modId) collisions. Without this layered
# read, +4 weapons score 0 here and get filtered out of the candidate
# pool entirely.
_item_mod_map: dict[tuple[int, int], int] = {}
for sql_path in [
    ROOT / 'sql' / 'item_mods.sql',
    ROOT / 'sql' / 'zz_custom_naked_item_mods.sql',
]:
    if not sql_path.exists():
        continue
    with sql_path.open(encoding='utf-8', errors='replace') as f:
        for line in f:
            m = re.match(r"^INSERT INTO `item_mods` VALUES \((\d+),(\d+),(-?\d+)\)", line)
            if m:
                iid, mid, val = int(m.group(1)), int(m.group(2)), int(m.group(3))
                _item_mod_map[(iid, mid)] = val

item_mods: dict[int, list[tuple[int, int]]] = defaultdict(list)
for (iid, mid), val in _item_mod_map.items():
    item_mods[iid].append((mid, val))


item_latents: dict[int, list[dict]] = defaultdict(list)
with (ROOT / 'sql' / 'item_latents.sql').open(encoding='utf-8', errors='replace') as f:
    for line in f:
        m = re.match(
            r"^INSERT INTO `item_latents` VALUES \((\d+),(\d+),(-?\d+),(-?\d+),(-?\d+)\)",
            line,
        )
        if m:
            item_latents[int(m.group(1))].append({
                'modId':       int(m.group(2)),
                'value':       int(m.group(3)),
                'latentId':    int(m.group(4)),
                'latentParam': int(m.group(5)),
            })

print(f"Parsed: {len(items_base)} items, {len(equip)} equippables, "
      f"{len(weapon_stats)} weapons with stats, {len(item_mods)} with mods, "
      f"{len(item_latents)} with latents")


# ============================================================================
# Weapon category map -- skill ID -> (category label, catalog var name)
# Source: src/map/entities/battleentity.h SkillType enum, cross-referenced
#         with gear_progression_catalog.lua emptyCategories() labels.
# ============================================================================
WEAPON_CATEGORY = {
    1:  ('Hand-to-Hand', 'h2h'),
    2:  ('Daggers',      'daggers'),
    3:  ('Swords',       'swords'),
    4:  ('Great Swords', 'greatswords'),
    5:  ('Axes',         'axes'),
    6:  ('Great Axes',   'greataxes'),
    7:  ('Scythes',      'scythes'),
    8:  ('Polearms',     'polearms'),
    9:  ('Katana',       'katana'),
    10: ('Great Katana', 'gkatana'),
    11: ('Clubs',        'clubs'),
    12: ('Staves',       'staves'),
    25: ('Archery',      'archery'),
    26: ('Marksmanship', 'marksmanship'),
}


# ============================================================================
# Job map + role classification -- mirrors score_armor.py
# ============================================================================
JOB = {n: 1 << i for i, n in enumerate(
    ['WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK',
     'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'SMN', 'BLU',
     'COR', 'PUP', 'DNC', 'SCH', 'GEO', 'RUN'])}

ROLE_JOBS = {
    'DD':     ['WAR', 'MNK', 'THF', 'DRK', 'BST', 'BRD', 'RNG', 'SAM',
               'NIN', 'DRG', 'BLU', 'COR', 'DNC', 'PUP', 'RUN'],
    'TANK':   ['PLD', 'RUN', 'WAR', 'NIN'],
    'CASTER': ['BLM', 'SCH', 'GEO', 'SMN', 'RDM'],
    'HEAL':   ['WHM', 'SCH', 'RDM', 'BRD', 'GEO'],
}
ROLE_MASKS = {role: sum(JOB[j] for j in jobs) for role, jobs in ROLE_JOBS.items()}


# ============================================================================
# Mod weights -- same numbers as score_armor.py for cross-tool consistency
# ============================================================================
ROLE_WEIGHTS = {
    'DD': {
        8: 2.0, 9: 2.0, 23: 1.0, 25: 1.5, 62: 5.0, 73: 2.0,
        165: 4.0, 259: 8.0, 288: 6.0, 302: 8.0, 384: 0.05,
        289: 0.5, 387: -3.0, 421: 1.5,
        840: 2.0, 841: 1.0, 570: 0.5,       # WS dmg: all-hits / first-hit / single-WS
    },
    'TANK': {
        10: 2.0, 2: 0.5, 3: 3.0, 1: 1.0, 63: 3.0, 27: 3.0, 29: 3.0,
        387: -8.0, 389: -8.0,
    },
    'CASTER': {
        12: 2.0, 13: 1.0, 28: 3.0, 30: 2.0, 311: 4.0, 170: 2.0,
        5: 0.05, 6: 1.0,
    },
    'HEAL': {
        13: 2.0, 14: 0.5, 5: 0.05, 6: 1.5, 369: 30.0, 374: 2.0,
        170: 2.0, 30: 1.0,
    },
}
DD_ALWAYS_LATENTS = {7, 10, 41}
CAP_DEFAULT = 200
MOD_SANITY_CAP = {
    62: 30, 63: 30, 165: 20, 170: 30, 259: 15, 288: 20, 302: 20,
    369: 10, 384: 300, 387: 30, 389: 30, 421: 30,
    570: 50, 840: 50, 841: 50,   # WS damage mods (per 1%)
}


def _clamp(mid: int, val: int) -> int:
    cap = MOD_SANITY_CAP.get(mid, CAP_DEFAULT)
    if val > cap:   return cap
    if val < -cap:  return -cap
    return val


# Weapon-specific: a high-DMG slow weapon shows DPS roughly proportional to
# dmg*60/delay. Multiplying by this weight folds raw output into the score.
DPS_WEIGHT = 2.0


def score_weapon(iid: int, role: str) -> float:
    weights = ROLE_WEIGHTS[role]
    score = 0.0
    for mid, val in item_mods.get(iid, []):
        w = weights.get(mid)
        if w:
            score += _clamp(mid, val) * w
    for row in item_latents.get(iid, []):
        w = weights.get(row['modId'])
        if not w:
            continue
        full = role == 'DD' and row['latentId'] in DD_ALWAYS_LATENTS
        score += _clamp(row['modId'], row['value']) * w * (1.0 if full else 0.5)
    # DPS bonus for ALL roles (a stronger weapon helps every wielder).
    ws = weapon_stats.get(iid)
    if ws and ws['delay'] > 0:
        score += (ws['dmg'] * 60 / ws['delay']) * DPS_WEIGHT
    return score


# ============================================================================
# Candidate set: iLvl 119+ weapons in our 14 categories
# ============================================================================
candidates: list[dict] = []
for iid, info in items_base.items():
    e = equip.get(iid)
    if not e:
        continue
    if e['ilevel'] < 119:
        continue
    ws = weapon_stats.get(iid)
    if not ws:
        continue
    if ws['skill'] not in WEAPON_CATEGORY:
        continue
    if not item_mods.get(iid) and not item_latents.get(iid):
        continue
    # Multi-job filter: REMA/Aeonic single-job weapons are handled by the
    # Reforge System catalog, not the Weapons Vendor. Keep cross-job items.
    if bin(e['jobs']).count('1') < 2:
        continue
    # Explicit +4 exclusion (belt-and-suspenders on top of the multi-job
    # filter above). +4 reforge sets are an Infamy Vendor exclusive (see
    # modules/custom/lua/dungeon_catalog.lua catalog.plus4Sets). Even if
    # the multi-job rule gets relaxed for some future tweak, this line
    # keeps +4 pieces out of the regular Weapons Vendor catalog. Mirrored
    # in tools/score_armor.py.
    if items_base[iid]['name'].endswith('_+4'):
        continue

    per_role = {}
    for role in ROLE_WEIGHTS:
        if (e['jobs'] & ROLE_MASKS[role]) == 0:
            continue
        s = score_weapon(iid, role)
        if s > 0:
            per_role[role] = s
    if not per_role:
        continue
    ceiling = max(per_role.values())
    candidates.append({
        'id':       iid,
        'name':     info['name'],
        'category': WEAPON_CATEGORY[ws['skill']][0],
        'cat_var':  WEAPON_CATEGORY[ws['skill']][1],
        'jobs':     e['jobs'],
        'ilevel':   e['ilevel'],
        'dmg':      ws['dmg'],
        'delay':    ws['delay'],
        'roles':    per_role,
        'ceiling':  ceiling,
    })

print(f"Viable ilvl>=119 weapon candidates: {len(candidates)}")


# ============================================================================
# Tier bucketing: FIXED score bands + top-5-per-CATEGORY Infamy skim
#   (replaces the 33rd/66th percentile split — owner request 2026-06-05).
#   Same bands as score_armor.py (Bronze<=200 / Silver 201-250 / Gold 251+),
#   but the Infamy skim is per WEAPON CATEGORY (the weapon analogue of an
#   armor slot): the 5 highest-scoring weapons per category (family-deduped)
#   are pulled OUT of the Weapons Vendor into an Infamy-exclusive tier and
#   promoted to the Dungeon Infamy Vendor by build_infamy_top_picks.py.
#   catalog.infamy is inert for the Weapons NPC (reads bronze/silver/gold
#   only) and for docgen (binds those three tiers only).
# ============================================================================
BRONZE_MAX, SILVER_MAX = 200, 250
INFAMY_TOP_PER_CAT = 5

_inf_fam_re = re.compile(r"\s*\+\d+\s*$")
def _inf_family(nm: str) -> str:
    return _inf_fam_re.sub("", nm.replace("_", " ")).strip()
def _inf_rank(nm: str) -> int:
    mm = re.search(r"\+(\d+)\s*$", nm.replace("_", " "))
    return int(mm.group(1)) if mm else 0

infamy_ids: set[int] = set()
for _cat_label, _ in WEAPON_CATEGORY.values():
    _best: dict[str, dict] = {}
    for c in (x for x in candidates if x['category'] == _cat_label):
        fam = _inf_family(c['name'])
        cur = _best.get(fam)
        if (cur is None
                or _inf_rank(c['name']) > _inf_rank(cur['name'])
                or (_inf_rank(c['name']) == _inf_rank(cur['name'])
                    and c['ceiling'] > cur['ceiling'])):
            _best[fam] = c
    for c in sorted(_best.values(), key=lambda x: -x['ceiling'])[:INFAMY_TOP_PER_CAT]:
        infamy_ids.add(c['id'])

for c in candidates:
    if c['id'] in infamy_ids:
        c['tier'] = 'infamy'
    elif c['ceiling'] <= BRONZE_MAX:
        c['tier'] = 'bronze'
    elif c['ceiling'] <= SILVER_MAX:
        c['tier'] = 'silver'
    else:
        c['tier'] = 'gold'

print(f"Tier bands: Bronze<=200 | Silver 201-250 | Gold 251+ | "
      f"Infamy = top {INFAMY_TOP_PER_CAT}/category ({len(infamy_ids)} weapons -> Infamy Vendor)")


# Counts
tier_cat_count = Counter((c['tier'], c['category']) for c in candidates)
print("\nWeapon counts by tier x category:")
for tier in ('bronze', 'silver', 'gold'):
    print(f"  {tier.capitalize()}")
    for cat_label, _ in WEAPON_CATEGORY.values():
        n = tier_cat_count[(tier, cat_label)]
        print(f"    {cat_label:14s} {n:>3d}")


# ============================================================================
# Per-category top-N picker with family roll-up
# ============================================================================
# 'infamy' cost is cosmetic — the real Infamy price for promoted weapons is
# assigned by tools/build_infamy_top_picks.py in catalog.vendorItemsAuto.
TIER_COST = {'bronze': 12, 'silver': 25, 'gold': 50, 'infamy': 500}
TOP_PER_BUCKET = 8       # weapons need fewer slots than armor (skill specialisation)
MIN_PER_JOB    = 1       # at least 1 weapon-cat option per applicable job

_PLUS_SUFFIX_RE = re.compile(r"\s*\+\d+\s*$")
def base_family(name: str) -> str:
    return _PLUS_SUFFIX_RE.sub("", name).strip()
def upgrade_rank(name: str) -> int:
    m = re.search(r"\+(\d+)\s*$", name)
    return int(m.group(1)) if m else 0
def dedup_by_family(bucket: list[dict]) -> list[dict]:
    keep: dict[str, dict] = {}
    for c in bucket:
        family = base_family(c['name'].replace('_', ' '))
        cur = keep.get(family)
        if cur is None:
            keep[family] = c
            continue
        cur_rank = upgrade_rank(cur['name'].replace('_', ' '))
        new_rank = upgrade_rank(c['name'].replace('_', ' '))
        if new_rank > cur_rank:
            keep[family] = c
        elif new_rank == cur_rank and c['ceiling'] > cur['ceiling']:
            keep[family] = c
    return list(keep.values())


def js_jobs(bits: int) -> str:
    inv = {v: k for k, v in JOB.items()}
    names = [inv[b] for b in inv if (bits & b)]
    return '/'.join(names) if names else '?'


all_selected: dict[tuple[str, str], list[dict]] = {}

def select_bucket(tier_name: str, category: str) -> list[dict]:
    bucket = [c for c in candidates if c['tier'] == tier_name and c['category'] == category]
    bucket = dedup_by_family(bucket)
    selected: dict[int, dict] = {}

    per_role_top = max(2, TOP_PER_BUCKET // len(ROLE_WEIGHTS))
    for role in ROLE_WEIGHTS:
        role_picks = sorted(
            (c for c in bucket if role in c['roles']),
            key=lambda x: -x['roles'][role],
        )[:per_role_top]
        for c in role_picks:
            selected.setdefault(c['id'], c)

    if len(selected) < TOP_PER_BUCKET:
        for c in sorted(bucket, key=lambda x: -x['ceiling']):
            if c['id'] not in selected:
                selected[c['id']] = c
                if len(selected) >= TOP_PER_BUCKET:
                    break

    # Per-job backfill: weapons specialise, so only check jobs that USE the
    # category. We check across the whole bucket to find an item the job can
    # equip; if none exists, that's a real gap in the DB.
    applicable_jobs = set()
    for c in bucket:
        for jname, jbit in JOB.items():
            if c['jobs'] & jbit:
                applicable_jobs.add(jname)

    for jname in applicable_jobs:
        jbit = JOB[jname]
        cur = sum(1 for c in selected.values() if c['jobs'] & jbit)
        need = MIN_PER_JOB - cur
        if need <= 0:
            continue
        for c in sorted(
            (c for c in bucket if (c['jobs'] & jbit) and c['id'] not in selected),
            key=lambda x: -x['ceiling'],
        )[:need]:
            selected[c['id']] = c

    return sorted(selected.values(), key=lambda x: -x['ceiling'])


# ============================================================================
# Lua emission -- patches gear_progression_catalog.lua in place
# ============================================================================
def tier_block(tier_name: str) -> str:
    lines = [f"catalog.{tier_name} = {{ weapons = emptyCategories() }}", "do"]
    for skill_id, (cat_label, cat_var) in WEAPON_CATEGORY.items():
        rows = select_bucket(tier_name, cat_label)
        all_selected[(tier_name, cat_label)] = rows
        if not rows:
            continue
        lines.append(f"    -- {cat_label}: {len(rows)} pick(s)")
        lines.append(f"    local {cat_var} = cat(catalog.{tier_name}.weapons, '{cat_label}')")
        for c in rows:
            cost = TIER_COST[tier_name]
            name = c['name'].replace('_', ' ').title().replace("'S", "'s")
            jobs = js_jobs(c['jobs'])
            best_role = max(c['roles'], key=c['roles'].get)
            score = c['roles'][best_role]
            lines.append(
                f"    table.insert({cat_var}, "
                f"{{ id = {c['id']}, name = \"{name}\", cost = {cost}, "
                f"jobs = '{jobs}' }})  -- {best_role} score {score:.0f}, "
                f"DMG {c['dmg']}/Dly {c['delay']}"
            )
        lines.append("")
    lines.append("end")
    return "\n".join(lines)


def infamy_block() -> str:
    """Emit catalog.infamy.weapons — exactly the top-5-per-category weapons
    skimmed above (tier == 'infamy'), highest score first. Same row shape as
    the gear tiers so build_infamy_top_picks.py parses the score comment.
    Not routed through select_bucket — the Infamy tier is the raw top-5."""
    lines = ["catalog.infamy = { weapons = emptyCategories() }", "do"]
    for skill_id, (cat_label, cat_var) in WEAPON_CATEGORY.items():
        rows = sorted(
            (c for c in candidates if c['tier'] == 'infamy' and c['category'] == cat_label),
            key=lambda x: -x['ceiling'],
        )
        all_selected[('infamy', cat_label)] = rows
        if not rows:
            continue
        # Distinct 'inf_' var prefix: the bronze/silver/gold tiers all reuse
        # the bare category var (e.g. `local swords`), so a shared name would
        # be ambiguous to build_infamy_top_picks' last-wins binding parser.
        inf_var = f"inf_{cat_var}"
        lines.append(f"    -- {cat_label}: {len(rows)} pick(s) -> Infamy Vendor")
        lines.append(f"    local {inf_var} = cat(catalog.infamy.weapons, '{cat_label}')")
        for c in rows:
            name = c['name'].replace('_', ' ').title().replace("'S", "'s")
            jobs = js_jobs(c['jobs'])
            best_role = max(c['roles'], key=c['roles'].get)
            score = c['roles'][best_role]
            lines.append(
                f"    table.insert({inf_var}, "
                f"{{ id = {c['id']}, name = \"{name}\", cost = {TIER_COST['infamy']}, "
                f"jobs = '{jobs}' }})  -- {best_role} score {score:.0f}, "
                f"DMG {c['dmg']}/Dly {c['delay']}"
            )
        lines.append("")
    lines.append("end")
    return "\n".join(lines)


catalog_path = ROOT / 'modules' / 'custom' / 'lua' / 'gear_progression_catalog.lua'
original = catalog_path.read_text(encoding='utf-8', errors='replace')

# Replace from "-- BRONZE TIER" through (but not including) "return catalog"
m_start = re.search(
    r"^-{10,}\s*\n--\s*BRONZE TIER\b.*?(?=^return\s+catalog\s*$)",
    original,
    re.MULTILINE | re.DOTALL,
)
m_end   = re.search(r"^return\s+catalog\s*$", original, re.MULTILINE)
assert m_start and m_end, (
    "Couldn't locate BRONZE TIER header / return catalog in "
    "gear_progression_catalog.lua. Has the file been hand-edited beyond "
    "what the patch logic expects?"
)

before = original[:m_start.start()]
after  = original[m_end.start():]

new_middle = []
new_middle.append("-----------------------------------")
new_middle.append("-- BRONZE TIER  (auto-generated by tools/score_weapons.py)")
new_middle.append("--   Role-balanced top picks per weapon category, expanded as needed")
new_middle.append("--   to guarantee >= " + str(MIN_PER_JOB) + " option per applicable job.")
new_middle.append("--   To regenerate after edits to weights or new DB content:")
new_middle.append("--     python tools/score_weapons.py")
new_middle.append("-----------------------------------")
new_middle.append(tier_block('bronze'))
new_middle.append("")
new_middle.append("-----------------------------------")
new_middle.append("-- SILVER TIER")
new_middle.append("-----------------------------------")
new_middle.append(tier_block('silver'))
new_middle.append("")
new_middle.append("-----------------------------------")
new_middle.append("-- GOLD TIER")
new_middle.append("-----------------------------------")
new_middle.append(tier_block('gold'))
new_middle.append("")
new_middle.append("-----------------------------------")
new_middle.append("-- INFAMY TIER  (top-5-per-category; promoted to the Dungeon Infamy")
new_middle.append("--   Vendor by tools/build_infamy_top_picks.py. Inert here: the")
new_middle.append("--   Weapons NPC only sells bronze/silver/gold.)")
new_middle.append("-----------------------------------")
new_middle.append(infamy_block())
new_middle.append("")

catalog_path.write_text(before + "\n".join(new_middle) + after, encoding='utf-8', newline='\n')

total = sum(len(rows) for rows in all_selected.values())
print(f"\nWrote {catalog_path}")
print(f"Total weapons in catalog: {total}")
print(f"  ({len(all_selected)} buckets, MIN_PER_JOB={MIN_PER_JOB}, soft floor TOP_PER_BUCKET={TOP_PER_BUCKET})")

print("\nBucket sizes (tier x category):")
for tier in ('bronze', 'silver', 'gold'):
    print(f"  {tier.capitalize()}")
    for cat_label, _ in WEAPON_CATEGORY.values():
        n = len(all_selected.get((tier, cat_label), []))
        print(f"    {cat_label:14s} {n:>3d}")
