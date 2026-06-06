"""Score accessories by stat value per role, bucket into Bronze/Silver/Gold.

Sibling to tools/score_armor.py and tools/score_weapons.py. Same parsing
and role-weight framework, three accessory-specific differences:

  1. SLOT MAP — bitmask values for the 5 accessory slots:
        Neck    = 512    (bit 9)
        Waist   = 1024   (bit 10)
        Earring = 6144   (bits 11+12 — either ear)
        Ring    = 24576  (bits 13+14 — either ring)
        Back    = 32768  (bit 15)

  2. NO iLVL FLOOR — many top-tier accessories (Moonshade Earring,
     Defending Ring, Rajas Ring, the entire pre-119 tier) carry
     ilevel=0 in the DB but are still BiS at endgame. Score-based
     bucketing is the only honest filter for accessories.

  3. RELAXED MULTI-JOB FILTER — accessory pools are smaller, so we
     keep single-job-only pieces too (Eschan accessories, JSE necks).
     The armor scorer's "must equip on 2+ jobs" rule belongs to that
     domain alone.

Outputs:
    1. Counts per (tier, slot)
    2. Top N picks per (tier, slot)
    3. Lua snippet at modules/custom/lua/accessory_catalog.lua

Re-run any time the DB or weight maps change.
"""
from __future__ import annotations

import re
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(r"D:/server")
OUT_LUA = ROOT / "modules" / "custom" / "lua" / "accessory_catalog.lua"


# ============================================================================
# SQL parsers — same shape as score_armor.py
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
        # itype (field 5) lets us drop weapons that happen to slot in
        # the same fields as accessories (Knobkierrie is @WEAPON_TYPE
        # in the ammo slot — not an accessory we want here).
        items_base[iid] = {
            'name':    fields[2].strip("'"),
            'itype':   fields[5],
            'is_rare': '@FLAG_RARE' in fields[7],
            'is_ex':   '@FLAG_EX'   in fields[7],
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


# item_mods loaded in TWO passes (upstream + zz_custom). Without the
# layered read, +4 accessories and ~1400 other naked items score 0
# here and get filtered out. See score_armor.py for the long version.
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
      f"{len(item_mods)} with mods, {len(item_latents)} with latents")


# ============================================================================
# Job bit map + roles — IDENTICAL to score_armor.py so a piece's "DD value"
# is the same number across the Armor NPC and the Accessory NPC.
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

ROLE_WEIGHTS = {
    'DD': {
        8: 2.0, 9: 2.0,
        23: 1.0, 25: 1.5,
        62: 5.0,
        73: 2.0,
        165: 4.0,
        259: 8.0,
        288: 6.0,
        302: 8.0,
        384: 0.05,
        289: 0.5,
        387: -3.0,
        421: 1.5,
    },
    'TANK': {
        10: 2.0,
        2: 0.5, 3: 3.0,
        1: 1.0, 63: 3.0,
        27: 3.0,
        29: 3.0,
        387: -8.0, 389: -8.0,
    },
    'CASTER': {
        12: 2.0, 13: 1.0,
        28: 3.0,
        30: 2.0,
        311: 4.0,
        170: 2.0,
        5: 0.05, 6: 1.0,
    },
    'HEAL': {
        13: 2.0, 14: 0.5,
        5: 0.05, 6: 1.5,
        369: 30.0,
        374: 2.0,
        170: 2.0,
        30: 1.0,
    },
}

DD_ALWAYS_LATENTS = {7, 10, 41}

CAP_DEFAULT = 200
MOD_SANITY_CAP = {
    62: 30, 63: 30, 165: 20, 170: 30, 259: 15, 288: 20, 302: 20,
    369: 10, 384: 300, 387: 30, 389: 30, 421: 30,
}


def _clamp(mid: int, val: int) -> int:
    cap = MOD_SANITY_CAP.get(mid, CAP_DEFAULT)
    if val > cap:   return cap
    if val < -cap:  return -cap
    return val


def score_item(iid: int, role: str) -> float:
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
        full_weight = role == 'DD' and row['latentId'] in DD_ALWAYS_LATENTS
        score += _clamp(row['modId'], row['value']) * w * (1.0 if full_weight else 0.5)
    return score


# ============================================================================
# Accessory-specific slot map. Single-bit slots map directly; the
# "either ear" (6144) and "either ring" (24576) shapes get their own
# names. Items with other bits set (head/body/hands/legs/feet/main/sub)
# are intentionally ignored — those belong to the armor or weapons
# scorers, not this one.
# ============================================================================
SLOT_NAMES = {
    512:    'neck',
    1024:   'waist',
    6144:   'ear',
    24576:  'ring',
    32768:  'back',
}

# ============================================================================
# Sortie JSE +2 earrings (Boii → Erilaz, one per job, ids 25422..25548 step 6).
# Owner request 2026-06-05: these are Infamy-Vendor EXCLUSIVES — the Accessory
# NPC does not sell them. They're excluded from the bronze/silver/gold pools
# below and emitted into catalog.infamy regardless of score. The role-balance
# algorithm scores them 0–63 (often 0 — their narrow single-job stats aren't in
# the weight maps), so they can't be placed by score; the override is the only
# honest way to surface them. Accessory (re)scoring is being revisited
# separately; for now only this earring set moves, the rest of the Accessory
# NPC's tiers are untouched.
# ============================================================================
SORTIE_EARRING_IDS = set(range(25422, 25549, 6))   # 22 ids, step 6
assert len(SORTIE_EARRING_IDS) == 22, "expected 22 Sortie JSE +2 earrings"


# ============================================================================
# Build the candidate set
# ============================================================================
candidates: list[dict] = []
for iid, info in items_base.items():
    e = equip.get(iid)
    if not e:
        continue
    if iid in SORTIE_EARRING_IDS:
        continue   # Infamy-Vendor exclusive — emitted into catalog.infamy below
    if e['slot'] not in SLOT_NAMES:
        continue
    # @WEAPON_TYPE / @USABLE_TYPE / etc. — only @EQUIPMENT_TYPE truly
    # counts as an accessory here. Knobkierrie (@WEAPON_TYPE in slot
    # 8) gets filtered out by the slot check above anyway, but the
    # type check is cheap and defensive.
    if info['itype'] != '@EQUIPMENT_TYPE':
        continue
    if not item_mods.get(iid) and not item_latents.get(iid):
        continue
    # No iLVL floor for accessories — Moonshade Earring (ilevel=0),
    # Defending Ring (ilevel=0), and other classic BiS pre-119 pieces
    # have ilevel=0 in the DB but are still endgame relevant. Tier
    # bucketing by ceiling score handles their ranking honestly.

    per_role = {}
    for role in ROLE_WEIGHTS:
        if (e['jobs'] & ROLE_MASKS[role]) == 0:
            continue
        s = score_item(iid, role)
        if s > 0:
            per_role[role] = s

    if not per_role:
        continue
    ceiling = max(per_role.values())
    candidates.append({
        'id':      iid,
        'name':    info['name'],
        'slot':    SLOT_NAMES[e['slot']],
        'jobs':    e['jobs'],
        'ilevel':  e['ilevel'],
        'level':   e['level'],
        'is_rare': info['is_rare'],
        'is_ex':   info['is_ex'],
        'roles':   per_role,
        'ceiling': ceiling,
    })

print(f"Viable accessory candidates: {len(candidates)}")


# ----------------------------------------------------------------------------
# Sortie JSE +2 earrings — gather data for the Infamy override block. They're
# excluded from `candidates` above, so score them here for the comment line.
# ----------------------------------------------------------------------------
sortie_earrings: list[dict] = []
for iid in sorted(SORTIE_EARRING_IDS):
    info = items_base.get(iid)
    e = equip.get(iid)
    if not info or not e:
        continue
    per = {}
    for role in ROLE_WEIGHTS:
        if (e['jobs'] & ROLE_MASKS[role]) == 0:
            continue
        sc = score_item(iid, role)
        if sc > 0:
            per[role] = sc
    if per:
        best_role = max(per, key=per.get)
        best_score = per[best_role]
    else:
        # No positive role score — fall back to the wearer's primary role so
        # build_infamy_top_picks' "<ROLE> score <N>" regex still matches.
        best_role = next((r for r in ('DD', 'TANK', 'CASTER', 'HEAL')
                          if e['jobs'] & ROLE_MASKS[r]), 'DD')
        best_score = 0.0
    sortie_earrings.append({
        'id': iid, 'name': info['name'], 'jobs': e['jobs'],
        'role': best_role, 'score': best_score,
    })
print(f"Sortie JSE +2 earrings for Infamy override: {len(sortie_earrings)}")


by_slot: dict[str, list[dict]] = defaultdict(list)
for c in candidates:
    by_slot[c['slot']].append(c)

# ============================================================================
# Infamy skim: top-5-per-slot (family-deduped), consistent with the armor /
# weapons scorers. The 5 highest-ceiling accessories per slot are pulled into
# an Infamy-exclusive tier (catalog.infamy) ALONGSIDE the Sortie earrings.
# Owner decision 2026-06-06: accessory Bronze/Silver/Gold KEEP the per-slot
# percentile split below (accessory scores top out ~76, so the armor-scale
# fixed bands don't transfer) — only this Infamy top-5 promotion is new.
# ============================================================================
INFAMY_TOP_PER_SLOT = 5
_inf_fam_re = re.compile(r"\s*\+\d+\s*$")
def _inf_family(nm: str) -> str:
    return _inf_fam_re.sub("", nm.replace("_", " ")).strip()
def _inf_rank(nm: str) -> int:
    mm = re.search(r"\+(\d+)\s*$", nm.replace("_", " "))
    return int(mm.group(1)) if mm else 0

infamy_ids: set[int] = set()
for slot, lst in by_slot.items():
    best: dict[str, dict] = {}
    for c in lst:
        fam = _inf_family(c['name'])
        cur = best.get(fam)
        if (cur is None
                or _inf_rank(c['name']) > _inf_rank(cur['name'])
                or (_inf_rank(c['name']) == _inf_rank(cur['name'])
                    and c['ceiling'] > cur['ceiling'])):
            best[fam] = c
    for c in sorted(best.values(), key=lambda x: -x['ceiling'])[:INFAMY_TOP_PER_SLOT]:
        infamy_ids.add(c['id'])

# ============================================================================
# Tier bucketing (33rd / 66th percentile of ceiling), PER SLOT — neck and ring
# scores live on different scales (rings pack double-stat clauses, necks pack
# WSD/etc.), so a global cut would skew the ratios. The Infamy top-5 are
# skimmed out first so they don't inflate the percentile thresholds.
# ============================================================================
print("\nTier thresholds (per slot, 33/66 percentile; top-5/slot -> Infamy):")
for slot, lst in by_slot.items():
    rest = [c for c in lst if c['id'] not in infamy_ids]
    scores_sorted = sorted(c['ceiling'] for c in rest)
    n = len(scores_sorted)
    p33 = scores_sorted[n // 3] if n else 0
    p66 = scores_sorted[(2 * n) // 3] if n else 0
    print(f"  {slot:5s} Bronze < {p33:6.1f} | Silver [{p33:6.1f}, {p66:6.1f}) | Gold >= {p66:6.1f}  "
          f"({n} tiered, {len(lst) - n} Infamy)")
    for c in lst:
        if c['id'] in infamy_ids:
            c['tier'] = 'infamy'
        elif c['ceiling'] >= p66:
            c['tier'] = 'gold'
        elif c['ceiling'] >= p33:
            c['tier'] = 'silver'
        else:
            c['tier'] = 'bronze'


tier_slot_count = Counter((c['tier'], c['slot']) for c in candidates)
print("\nPiece counts by tier x slot:")
for tier in ('bronze', 'silver', 'gold'):
    row = "  " + tier.capitalize().ljust(8)
    for slot in ('neck', 'waist', 'ear', 'ring', 'back'):
        row += f"{slot}:{tier_slot_count[(tier, slot)]:>4}  "
    print(row)


def js_jobs(bits: int) -> str:
    inv = {v: k for k, v in JOB.items()}
    names = [inv[b] for b in inv if (bits & b)]
    if len(names) == 22:
        return 'All'
    return '/'.join(names) if names else '?'


# ============================================================================
# Top-N per (tier, slot) with role-balanced selection. Same model as
# score_armor.py: each role gets its share of slots, then a coverage
# pass fills out per-job availability.
# ============================================================================
# Tier costs (medals per piece). Re-tuned after first-look review:
# Bronze 8→15 / Silver 18→32 / Gold 35→60. The earlier values let an
# attentive player blow through every Bronze slot in a single afternoon
# of HL rank-2 farming, which trivialized the progression curve. New
# numbers put the full Bronze-tier accessory set at ~150 Beastmens
# (roughly 30 NMs), Silver at ~320 Kindreds (~65 rank-3 NMs), and Gold
# at ~600 Demons. Mirrors the Armor NPC pacing instead of undercutting it.
# 'infamy' cost is cosmetic — the Sortie earrings live in catalog.infamy and
# their real Infamy price is assigned by tools/build_infamy_top_picks.py.
TIER_COST = {'bronze': 15, 'silver': 32, 'gold': 60, 'infamy': 300}
TOP_PER_BUCKET = 8
MIN_PER_JOB = 1


def role_balanced_picks(pool: list[dict], n: int) -> list[dict]:
    """Round-robin top-of-each-role until we hit n picks, then fill the
    remainder with the next-highest ceiling regardless of role."""
    by_role: dict[str, list[dict]] = defaultdict(list)
    for c in pool:
        for role, score in c['roles'].items():
            by_role[role].append((score, c))
    for role in by_role:
        by_role[role].sort(key=lambda t: -t[0])

    picked: list[dict] = []
    seen: set[int] = set()
    cursor = {role: 0 for role in by_role}
    roles = ['DD', 'TANK', 'CASTER', 'HEAL']
    while len(picked) < n:
        progress = False
        for role in roles:
            if cursor[role] >= len(by_role.get(role, [])):
                continue
            _, c = by_role[role][cursor[role]]
            cursor[role] += 1
            if c['id'] in seen:
                continue
            picked.append(c)
            seen.add(c['id'])
            progress = True
            if len(picked) >= n:
                break
        if not progress:
            break

    if len(picked) < n:
        rest = sorted((c for c in pool if c['id'] not in seen),
                      key=lambda c: -c['ceiling'])
        for c in rest:
            picked.append(c)
            seen.add(c['id'])
            if len(picked) >= n:
                break
    return picked


buckets: dict[tuple[str, str], list[dict]] = defaultdict(list)
for tier in ('bronze', 'silver', 'gold'):
    for slot in ('neck', 'waist', 'ear', 'ring', 'back'):
        pool = [c for c in candidates if c['tier'] == tier and c['slot'] == slot]
        buckets[(tier, slot)] = role_balanced_picks(pool, TOP_PER_BUCKET)


# Per-job coverage pass: every job should have at least MIN_PER_JOB
# options in each (tier, slot) bucket. If a job is starved, append
# next-best-by-ceiling picks the job can wear.
for (tier, slot), picks in buckets.items():
    pool = [c for c in candidates if c['tier'] == tier and c['slot'] == slot]
    pool_sorted = sorted(pool, key=lambda c: -c['ceiling'])
    in_bucket = {c['id'] for c in picks}
    for job_name, job_bit in JOB.items():
        count = sum(1 for c in picks if c['jobs'] & job_bit)
        if count >= MIN_PER_JOB:
            continue
        for c in pool_sorted:
            if c['id'] in in_bucket:
                continue
            if not (c['jobs'] & job_bit):
                continue
            picks.append(c)
            in_bucket.add(c['id'])
            count += 1
            if count >= MIN_PER_JOB:
                break
    buckets[(tier, slot)] = picks


# ============================================================================
# Pretty print top picks
# ============================================================================
print("\nTop picks per (tier, slot):\n")
for tier in ('bronze', 'silver', 'gold'):
    print(f"=== {tier.upper()} (cost {TIER_COST[tier]} medals) ===")
    for slot in ('neck', 'waist', 'ear', 'ring', 'back'):
        print(f"  -- {slot} --")
        for c in buckets[(tier, slot)]:
            top_role, top_score = max(c['roles'].items(), key=lambda kv: kv[1])
            flags = []
            if c['is_rare']: flags.append('RARE')
            if c['is_ex']:   flags.append('EX')
            flag_str = f" [{','.join(flags)}]" if flags else ""
            print(f"    {c['ceiling']:7.1f}  {c['name']:32s}  "
                  f"{top_role}={top_score:.1f}  jobs={js_jobs(c['jobs'])}{flag_str}")


# ============================================================================
# Emit accessory_catalog.lua
# ============================================================================
def jobs_str(bits: int) -> str:
    inv = {v: k for k, v in JOB.items()}
    names = [inv[b] for b in inv if (bits & b)]
    return '/'.join(names) if names and len(names) < 22 else 'All'


def display_name(snake: str) -> str:
    return ' '.join(w[0].upper() + w[1:] if w else w for w in snake.split('_'))


def lua_q(s: str) -> str:
    return "'" + s.replace("\\", "\\\\").replace("'", "\\'") + "'"


lines: list[str] = [
    "-----------------------------------",
    "-- accessory_catalog.lua",
    "-- Endgame accessories for the Accessory NPC.",
    "-- Covers Neck / Waist / Earring / Ring / Back.",
    "--",
    "-- Tiers (medal currencies, same trio as Armor / Weapons NPCs):",
    "--   Bronze   = Beastmens Medal   (entry)",
    "--   Silver   = Kindreds Medal    (mid)",
    "--   Gold     = Demons Medal      (BiS endgame)",
    "--",
    "-- HOW THIS FILE IS MAINTAINED:",
    "--   * Placement config (zoneId/zonePath/vendorPos/seals/goldExtraDrop)",
    "--     is rewritten on every regen, sourced from constants at the top",
    "--     of tools/score_accessories.py. If you want the NPC somewhere",
    "--     else, edit those constants.",
    "--   * Tier contents (the table.insert blocks below) are scored from",
    "--     the live item DB and rewritten on every regen.",
    "--",
    "-- AUTO-GENERATED by tools/score_accessories.py — do NOT hand-edit.",
    "-- To regenerate after the DB or weight maps change:",
    "--     python tools/score_accessories.py",
    "-- (or run tools/rebalance_all.bat to re-rank every gear catalog at once)",
    "-----------------------------------",
    "local catalog = {}",
    "",
    "-----------------------------------",
    "-- ZONE / NPC PLACEMENT",
    "--   Single source of truth for:",
    "--     - Accessory_NPC.lua : override registration + NPC position",
    "--     - docgen            : gear-vendors.md location table + zone prose",
    "--   Sits next to the Armor NPC and Weapons NPC at Reisenjima Henge",
    "--   so players don't zone-hop between gear vendors.",
    "-----------------------------------",
    "catalog.zoneId    = xi.zone.REISENJIMA_HENGE",
    "catalog.zonePath  = 'xi.zones.Reisenjima_Henge'",
    "catalog.vendorPos = { x = 8.4861, y = 5.5090, z = -12.1827, rot = 230 }",
    "",
    "-----------------------------------",
    "-- SEAL CURRENCY DEFINITIONS (shared with Armor / Weapons NPCs)",
    "-----------------------------------",
    "catalog.seals =",
    "{",
    "    bronze = { id = 9539, name = 'Beastmens Medal' },",
    "    silver = { id = 9541, name = 'Kindreds Medal'  },",
    "    gold   = { id = 9543, name = 'Demons Medal'    },",
    "}",
    "",
    "-- Gold-tier extra requirement: disabled. Mirrors the Armor NPC's",
    "-- pattern — set this to { id = X, qty = N, name = '...' } if you",
    "-- want Gold accessories to require an additional drop on top of",
    "-- the seal cost. With nil, Gold accessories cost only the medal.",
    "catalog.goldExtraDrop = nil",
    "",
    "-----------------------------------",
    "-- Helper: empty slot tables for a tier",
    "-----------------------------------",
    "local function emptySlots()",
    "    return { neck = {}, waist = {}, ear = {}, ring = {}, back = {} }",
    "end",
    "",
]

# Short-binding pattern, identical shape to armor_catalog.lua:
#   local b = catalog.bronze ; table.insert(b.neck, {...})
# This lets the docgen reuse the same regex it uses for armor.
TIER_VAR = {'bronze': 'b', 'silver': 's', 'gold': 'g'}

for tier in ('bronze', 'silver', 'gold'):
    var = TIER_VAR[tier]
    cost = TIER_COST[tier]
    lines.append(f"-----------------------------------")
    lines.append(f"-- {tier.upper()} TIER  ({cost} medals/piece)")
    lines.append(f"-----------------------------------")
    lines.append(f"catalog.{tier} = emptySlots()")
    lines.append(f"local {var} = catalog.{tier}")
    lines.append("")
    for slot in ('neck', 'waist', 'ear', 'ring', 'back'):
        picks = buckets[(tier, slot)]
        if not picks:
            continue
        lines.append(f"-- {slot}")
        for c in picks:
            # Score + flag tail goes AFTER the table close so Lua's
            # line-comment doesn't eat the closing braces.
            top_role, top_score = max(c['roles'].items(), key=lambda kv: kv[1])
            flag_bits = []
            if c['is_rare']: flag_bits.append('RARE')
            if c['is_ex']:   flag_bits.append('EX')
            flag_tail = f" [{','.join(flag_bits)}]" if flag_bits else ''
            comment = f"  -- {top_role} score {top_score:.0f}{flag_tail}"
            lines.append(
                f"table.insert({var}.{slot}, "
                f"{{ id = {c['id']:>6}, "
                f"name = {lua_q(display_name(c['name'])):<36s}, "
                f"cost = {cost:>3}, "
                f"jobs = {lua_q(jobs_str(c['jobs']))} }}){comment}"
            )
        lines.append("")
    lines.append("")

# ----------------------------------------------------------------------------
# INFAMY TIER — top-5-per-slot BiS accessories (score-based, like the armor /
# weapons scorers) PLUS the 22 Sortie JSE +2 earrings (owner override).
# Infamy-Vendor exclusive; promoted to the Dungeon Infamy Vendor by
# tools/build_infamy_top_picks.py. catalog.infamy is inert for the Accessory
# NPC (sells bronze/silver/gold only) and for docgen.
# ----------------------------------------------------------------------------
lines.append("-----------------------------------")
lines.append("-- INFAMY TIER  (top-5-per-slot BiS + Sortie JSE +2 earrings)")
lines.append("--   Not sold by the Accessory NPC. Promoted to the Dungeon Infamy")
lines.append("--   Vendor by tools/build_infamy_top_picks.py.")
lines.append("-----------------------------------")
lines.append("catalog.infamy = emptySlots()")
lines.append("local inf = catalog.infamy")
lines.append("")
for slot in ('neck', 'waist', 'ear', 'ring', 'back'):
    rows = sorted((c for c in candidates if c['tier'] == 'infamy' and c['slot'] == slot),
                  key=lambda x: -x['ceiling'])
    if not rows:
        continue
    lines.append(f"-- {slot} (top {len(rows)} by score -> Infamy Vendor)")
    for c in rows:
        top_role, top_score = max(c['roles'].items(), key=lambda kv: kv[1])
        flag_bits = []
        if c['is_rare']: flag_bits.append('RARE')
        if c['is_ex']:   flag_bits.append('EX')
        flag_tail = f" [{','.join(flag_bits)}]" if flag_bits else ''
        lines.append(
            f"table.insert(inf.{slot}, "
            f"{{ id = {c['id']:>6}, "
            f"name = {lua_q(display_name(c['name'])):<36s}, "
            f"cost = {TIER_COST['infamy']:>3}, "
            f"jobs = {lua_q(jobs_str(c['jobs']))} }})  -- {top_role} score {top_score:.0f}{flag_tail}"
        )
    lines.append("")
lines.append("-- ear (Sortie +2, one per job)")
for c in sortie_earrings:
    lines.append(
        f"table.insert(inf.ear, "
        f"{{ id = {c['id']:>6}, "
        f"name = {lua_q(display_name(c['name'])):<36s}, "
        f"cost = {TIER_COST['infamy']:>3}, "
        f"jobs = {lua_q(jobs_str(c['jobs']))} }})  -- {c['role']} score {c['score']:.0f}"
    )
lines.append("")
lines.append("")

lines.append("return catalog")
lines.append("")

OUT_LUA.write_text("\n".join(lines), encoding="utf-8")
print(f"\nWrote {OUT_LUA}")
print(f"  ({sum(len(v) for v in buckets.values())} items across "
      f"{len(buckets)} tier×slot buckets)")
