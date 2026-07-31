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

import os, json as _json
ROOT = Path(os.environ.get("SCORE_ROOT", r"D:/server"))

# Owner exclusivity rule (2026-07): bronze/silver/gold may ONLY sell gear that is
# EXCLUSIVE to the medal vendor. IDs obtainable elsewhere (mob drops, crafting, or
# any other custom content/vendor/forge catalog) are dropped from those tiers; the
# Infamy skim is exempt. Set built by tools/gen_vendor_exclusions.py.
_excl_path = Path(__file__).with_name('vendor_obtainable_elsewhere.json')
OBTAINABLE_ELSEWHERE = (frozenset(_json.loads(_excl_path.read_text(encoding='utf-8'))['ids'])
                        if _excl_path.exists() else frozenset())

# NPC-only / non-player junk to keep OUT of the scored vendor catalogs. Mirror
# of the list in tools/docgen/generators/gear_finder.py and the sibling scorers
# score_armor.py / score_accessories.py (and the DB purge in
# modules/custom/sql/zz_remove_judge_items.sql). Excluded by id AND name prefix
# at load time so a re-import can't slip them back in. Keep these copies in sync.
EXCLUDED_ITEM_IDS = frozenset({
    12332, 12523, 12551, 12679, 12807, 12935, 13074, 13215, 13358, 13505,
    13606, 16622, 17004, 17012, 17174, 17326, 17406, 17644, 19325,  # Judge* (Ballista)
    # Prime Weapons -- forge-ONLY at the GM Home Prime Armory (5 trials + 750M gil).
    # They reuse strong iLvl119 retail IDs (Naegling / Varga Purnikawa / Mpu Gandring
    # / ...), so the scorer would otherwise shelve them into the Weapons/Infamy vendors.
    21531, 21534, 21589, 21621, 21642, 21781, 21833, 21887, 21999, 22102, 22155, 22159,
})
EXCLUDED_NAME_PREFIXES = ('judge', 'prime_')   # 'prime_*' = generic Prime Armory forms

# Every custom Prime weapon FORM is forge-only (GM Home Prime Armory), not just the base
# id in EXCLUDED_ITEM_IDS above. The named forms reuse REMA/retail names and each has
# several upgrade-stage ids that SHARE one item_basic name (e.g. mpu_gandring = 21587-
# 21590), so exclude by exact name to catch every stage. See modules/custom/sql/
# prime_weapons_gear.sql for the authoritative set.  (2026-07-05: 21588 mpu_gandring
# leaked into the vendor because only the base id 21589 was id-excluded.)
PRIME_WEAPON_NAMES = frozenset({
    'caliburnus', 'dokoku', 'earp', 'foenaria', 'gae_buide', 'helheim',
    'kusanagi-no-tsurugi', 'laphria', 'lorg_mor', 'loughnashade', 'mpu_gandring',
    'naegling', 'opashoro', 'pinaka', 'spalirisos', 'varga_purnikawa',
})


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
        _nm = fields[2].strip("'")
        if (iid in EXCLUDED_ITEM_IDS or _nm.startswith(EXCLUDED_NAME_PREFIXES)
                or _nm in PRIME_WEAPON_NAMES):
            continue  # NPC-only junk (Judge*) or forge-only Prime weapon — never score it
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
from _item_mods import load_item_mod_map
# Merge EVERY item_mods source (base + all zz_ overlays + tier carry-forward),
# not just item_mods.sql + zz_custom_naked -- otherwise reforge/relic/Tokko gear
# and the carry-forward fixes are under-read and mis-scored.
_item_mod_map = load_item_mod_map(ROOT / 'sql')

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

# Relic/Empyrean/Mythic/Aeonic RANGED weapon families to keep OUT of the Weapons
# Vendor so the ultimate ranged weapons stay an EARNED reward (the ranged analogue
# of how single-job melee REMA route to the Reforge System). Matched by
# short_name prefix with '-' normalised to '_'. Archery: Yoichinoyumi (relic),
# Gandiva (empy), Fail-Not (aeonic). Marksmanship: Annihilator (relic),
# Armageddon (empy), Gastraphetes + Death Penalty (mythic). Applies to single- AND
# multi-job (e.g. Yoichinoyumi is RNG/SAM but still held back). Extend as needed.
RANGED_EXCLUDE = (
    'yoichinoyumi', 'gandiva', 'fail_not',
    'annihilator', 'armageddon', 'gastraphetes', 'death_penalty',
    # Other earned-only ultimate ranged tiers (owner 2026-06-13: cap these too) --
    # Prime (Odyssey), Su5 (Skirmish: Pinaka / Mpaca's), Ambuscade (Artemis's).
    'prime', 'pinaka', 'mpacas', 'artemiss',
)

# Relic/Empyrean MELEE weapon families to keep OUT of the Weapons Vendor -- the melee
# analogue of RANGED_EXCLUDE. Single-job melee REMA already route to the Reforge System
# (the multi-job filter in the candidate loop), but relaunch gives several REMA multi-job
# masks (e.g. Mandau = RDM/THF/BRD, Ragnarok = WAR/PLD/DRK, Claustrum, Verethragna,
# Twashtar, Almace, Caladbolg, Farsha, Hvergelmir), so they slip past that filter and
# must be named explicitly. Matched by name prefix ('-' -> '_'), single- AND multi-job.
# Ranged REMA live in RANGED_EXCLUDE; Ambuscade families (Kaja / Voluspa / Fomalhaut /
# Mpu Gandring / etc.) are NOT REMA and are intentionally left in.  (added 2026-07-05)
MELEE_REMA_EXCLUDE = (
    # Relic
    'spharai', 'mandau', 'excalibur', 'ragnarok', 'guttler', 'bravura', 'apocalypse',
    'gungnir', 'kikoku', 'amanomurakumo', 'mjollnir', 'claustrum', 'gjallarhorn',
    # Empyrean
    'verethragna', 'twashtar', 'almace', 'caladbolg', 'ukonvasara', 'farsha', 'redemption',
    'rhongomiant', 'kannagi', 'kogarasumaru', 'gambanteinn', 'hvergelmir', 'daurdabla',
)


# ============================================================================
# Job map + role classification -- mirrors score_armor.py
# ============================================================================
JOB = {n: 1 << i for i, n in enumerate(
    ['WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK',
     'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'SMN', 'BLU',
     'COR', 'PUP', 'DNC', 'SCH', 'GEO', 'RUN'])}

ROLE_JOBS = {
    'DPS':    ['WAR', 'MNK', 'THF', 'DRK', 'BST', 'BRD', 'RNG', 'SAM',
               'NIN', 'DRG', 'BLU', 'COR', 'DNC', 'PUP', 'RUN'],
    'WS':     ['WAR', 'MNK', 'THF', 'DRK', 'BST', 'BRD', 'RNG', 'SAM',
               'NIN', 'DRG', 'BLU', 'COR', 'DNC', 'PUP', 'RUN'],
    'TANK':   ['PLD', 'RUN', 'WAR', 'NIN'],
    'CASTER': ['BLM', 'SCH', 'GEO', 'SMN', 'RDM'],
    'HEAL':   ['WHM', 'SCH', 'RDM', 'BRD', 'GEO'],
    # PET role: pet/avatar gear (incl. pet-stat weapons) is SMN's real BiS
    # and never scored under CASTER. BST/PUP share the same pet-stat mods.
    'PET':    ['SMN', 'BST', 'PUP'],
}
ROLE_MASKS = {role: sum(JOB[j] for j in jobs) for role, jobs in ROLE_JOBS.items()}


# ============================================================================
# Mod weights -- same numbers as score_armor.py for cross-tool consistency
# ---------------------------------------------------------------------------
# Role weights, sanity caps and the DD-latent set live in ONE shared module
# (tools/scoring_weights.py) so the four scorers can never drift. EDIT WEIGHTS
# THERE, not here. (Previously each scorer kept its own hand-synced copy.)
# ---------------------------------------------------------------------------
try:
    from tools.scoring_weights import ROLE_WEIGHTS, MOD_SANITY_CAP, CAP_DEFAULT, DD_ALWAYS_LATENTS, score_latents
except ImportError:  # run as `python tools/score_*.py` (tools/ is sys.path[0])
    from scoring_weights import ROLE_WEIGHTS, MOD_SANITY_CAP, CAP_DEFAULT, DD_ALWAYS_LATENTS, score_latents


def _clamp(mid: int, val: int) -> int:
    cap = MOD_SANITY_CAP.get(mid, CAP_DEFAULT)
    if val > cap:   return cap
    if val < -cap:  return -cap
    return val


# Weapon-specific: a high-DMG slow weapon shows DPS roughly proportional to
# dmg*60/delay. Multiplying by this weight folds raw output into the score.
DPS_WEIGHT = 2.0
WS_DMG_WEIGHT = 0.5   # WS role: raw weapon base damage matters (heavy/slow weapons)
# Ranged weapons score low on the melee-tuned DMG terms, so without help they all
# cluster in Bronze. Multiply the ranged weapon-OUTPUT term so the (capped, non-
# ultimate) ranged pool spreads across Bronze/Silver/Gold like melee does.
# Per-skill because guns (Marksmanship, lower base DMG) need a bigger nudge than
# bows (Archery) to reach the upper tiers. Tune if the spread looks off.
# (Owner request 2026-06-13.)
RANGED_DMG_MULT = {25: 2.0, 26: 3.0}   # 25 Archery, 26 Marksmanship


def score_weapon(iid: int, role: str) -> float:
    weights = ROLE_WEIGHTS[role]
    score = 0.0
    for mid, val in item_mods.get(iid, []):
        w = weights.get(mid)
        if w:
            score += _clamp(mid, val) * w
    # score_latents buckets by (mod, lat) and takes max per bucket so
    # mutually-exclusive food/weather/day latents don't stack. See
    # scoring_weights.score_latents for the rationale (Roshi Jinpachi 380 fix).
    score += score_latents(
        ((row['modId'], row['value'], row['latentId'])
         for row in item_latents.get(iid, [])),
        weights, role,
    )
    # Weapon output: sustained DPS for the DPS role; raw base damage for WS.
    ws = weapon_stats.get(iid)
    if ws and ws['delay'] > 0:
        rmult = RANGED_DMG_MULT.get(ws['skill'], 1.0)
        if role == 'DPS':
            score += (ws['dmg'] * 60 / ws['delay']) * DPS_WEIGHT * rmult
        elif role == 'WS':
            score += ws['dmg'] * WS_DMG_WEIGHT * rmult
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
    # Drop AMMO from the ranged categories: arrows/bullets/bolts share the
    # Archery/Marksmanship skill but sit in the Ammo slot (0x08), while bows/guns
    # sit in the Ranged slot (0x04). The Weapons Vendor sells the weapons only.
    if ws['skill'] in (25, 26) and (e['slot'] & 0x08):
        continue
    if not item_mods.get(iid) and not item_latents.get(iid):
        continue
    # Multi-job filter: single-job MELEE weapons (REMA/Aeonic) are handled by the
    # Reforge System catalog, not the Weapons Vendor, so they're skipped. RANGED
    # is EXEMPT -- ranged jobs (RNG/COR) have no Reforge path, so single-job
    # Archery (25) / Marksmanship (26) weapons are kept in the Weapons Vendor.
    if bin(e['jobs']).count('1') < 2 and ws['skill'] not in (25, 26):
        continue
    # ...but the genuine ULTIMATE ranged weapons (Relic/Empy/Mythic/Aeonic) are
    # held back so they stay an earned reward, single- OR multi-job alike.
    if ws['skill'] in (25, 26):
        _rfam = items_base[iid]['name'].replace('-', '_')
        if any(_rfam.startswith(_r) for _r in RANGED_EXCLUDE):
            continue
    # Melee Relic/Empyrean held back the same way (they carry multi-job masks on
    # relaunch, so the single-job Reforge routing above doesn't catch them).
    _mfam = items_base[iid]['name'].replace('-', '_')
    if any(_mfam.startswith(_r) for _r in MELEE_REMA_EXCLUDE):
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

# Owner exclusivity: mark obtainable-elsewhere weapons with a sentinel tier so
# every selection path skips them in bronze/silver/gold (Infamy skim exempt).
_excl_n = 0
for c in candidates:
    if c['tier'] != 'infamy' and c['id'] in OBTAINABLE_ELSEWHERE:
        c['tier'] = '_excluded'
        _excl_n += 1
print(f"Vendor-exclusive filter: removed {_excl_n} obtainable-elsewhere weapons from bronze/silver/gold")

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

# Manual forced picks -- items the scorer's filters skip (e.g. every one-handed
# katana is EX + NIN-only single-job, so none score into the vendor) but that we
# still want sold. {(tier, category): [ {id, name, jobs, dmg, delay}, ... ]}.
# tier_block emits these AFTER the auto picks, so they survive a re-score.
MANUAL_PICKS = {
    ('gold',   'Katana'): [{'id': 21936, 'name': 'Yagyu Darkblade',     'jobs': 'NIN', 'dmg': 173, 'delay': 227}],
    # 2026-07: removed Ajja Katana (21919) + Koga Shinobi-Gatana (21915) [Weapon
    # Forge] and the gold Axes Dolichenus (21722) / Spalirisos (21730) [Weapon
    # Forge] / Aymur (21751) [Infamy Vendor] -- all obtainable elsewhere, so they
    # violate the medal-vendor exclusivity rule.
}
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
        manual = MANUAL_PICKS.get((tier_name, cat_label), [])
        if not rows and not manual:
            continue
        suffix = f" + {len(manual)} manual" if manual else ""
        lines.append(f"    -- {cat_label}: {len(rows)} pick(s){suffix}")
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
        for mp in manual:
            cost = TIER_COST[tier_name]
            lines.append(
                f"    table.insert({cat_var}, "
                f"{{ id = {mp['id']}, name = \"{mp['name']}\", cost = {cost}, "
                f"jobs = '{mp['jobs']}' }})  -- MANUAL, DMG {mp['dmg']}/Dly {mp['delay']}"
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

# Vendor placement is human-curated; scoring is advisory (recommendation tool only).
# The catalog is NOT overwritten unless you explicitly re-seed from scores. [decoupled 2026-07]
_wrote = False  # HARDCODED 2026-07-10: vendor auto-write DISABLED - gear_progression_catalog.lua is hand-curated
if _wrote:
    catalog_path.write_text(before + "\n".join(new_middle) + after, encoding='utf-8', newline='\n')

total = sum(len(rows) for rows in all_selected.values())
if _wrote:
    print(f"\nWrote {catalog_path}")
else:
    print(f"\n[scoring-only] {catalog_path.name} left untouched -- vendor placement is human-curated.")
    print(f"               Scores above feed the gear recommendation tool only.")
    print(f"               Auto-write is permanently DISABLED (2026-07-10); catalogs are hand-curated -- edit the .lua directly.")
print(f"Total weapons scored: {total}")
print(f"  ({len(all_selected)} buckets, MIN_PER_JOB={MIN_PER_JOB}, soft floor TOP_PER_BUCKET={TOP_PER_BUCKET})")

print("\nBucket sizes (tier x category):")
for tier in ('bronze', 'silver', 'gold'):
    print(f"  {tier.capitalize()}")
    for cat_label, _ in WEAPON_CATEGORY.values():
        n = len(all_selected.get((tier, cat_label), []))
        print(f"    {cat_label:14s} {n:>3d}")
