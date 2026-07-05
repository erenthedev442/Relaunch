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

import os, json as _json
ROOT = Path(os.environ.get("SCORE_ROOT", r"D:/server"))

# Owner exclusivity rule (2026-07): bronze/silver/gold may ONLY sell gear that is
# EXCLUSIVE to the medal vendor. IDs obtainable elsewhere (mob drops, crafting, or
# any other custom content/vendor/forge catalog) are dropped from those tiers; the
# Infamy skim is exempt. Set built by tools/gen_vendor_exclusions.py.
_excl_path = Path(__file__).with_name('vendor_obtainable_elsewhere.json')
OBTAINABLE_ELSEWHERE = (frozenset(_json.loads(_excl_path.read_text(encoding='utf-8'))['ids'])
                        if _excl_path.exists() else frozenset())
OUT_LUA = ROOT / "modules" / "custom" / "lua" / "accessory_catalog.lua"

# NPC-only / non-player junk to keep OUT of the scored vendor catalogs. Mirror
# of the list in tools/docgen/generators/gear_finder.py and the sibling scorers
# score_armor.py / score_weapons.py (and the DB purge in
# modules/custom/sql/zz_remove_judge_items.sql). Excluded by id AND name prefix
# at load time so a re-import can't slip them back in. Keep these copies in sync.
EXCLUDED_ITEM_IDS = frozenset({
    12332, 12523, 12551, 12679, 12807, 12935, 13074, 13215, 13358, 13505,
    13606, 16622, 17004, 17012, 17174, 17326, 17406, 17644, 19325,  # Judge* (Ballista)
})
EXCLUDED_NAME_PREFIXES = ('judge',)


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
        if iid in EXCLUDED_ITEM_IDS or fields[2].strip("'").startswith(EXCLUDED_NAME_PREFIXES):
            continue  # NPC-only / non-player junk (Judge* etc.) — never score it
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
    'DPS':    ['WAR', 'MNK', 'THF', 'DRK', 'BST', 'BRD', 'RNG', 'SAM',
               'NIN', 'DRG', 'BLU', 'COR', 'DNC', 'PUP', 'RUN'],
    'WS':     ['WAR', 'MNK', 'THF', 'DRK', 'BST', 'BRD', 'RNG', 'SAM',
               'NIN', 'DRG', 'BLU', 'COR', 'DNC', 'PUP', 'RUN'],
    'TANK':   ['PLD', 'RUN', 'WAR', 'NIN'],
    'CASTER': ['BLM', 'SCH', 'GEO', 'SMN', 'RDM'],
    'HEAL':   ['WHM', 'SCH', 'RDM', 'BRD', 'GEO'],
    # PET role: pet/avatar accessories (incl. the SMN sachets) are SMN's
    # real BiS and never scored under CASTER. BST/PUP share the pet mods.
    'PET':    ['SMN', 'BST', 'PUP'],
}
ROLE_MASKS = {role: sum(JOB[j] for j in jobs) for role, jobs in ROLE_JOBS.items()}

# ---------------------------------------------------------------------------
# Role weights, sanity caps and the DD-latent set live in ONE shared module
# (tools/scoring_weights.py) so the four scorers can never drift. EDIT WEIGHTS
# THERE, not here. (Previously each scorer kept its own hand-synced copy.)
# ---------------------------------------------------------------------------
try:
    from tools.scoring_weights import ROLE_WEIGHTS, MOD_SANITY_CAP, CAP_DEFAULT, DD_ALWAYS_LATENTS
except ImportError:  # run as `python tools/score_*.py` (tools/ is sys.path[0])
    from scoring_weights import ROLE_WEIGHTS, MOD_SANITY_CAP, CAP_DEFAULT, DD_ALWAYS_LATENTS


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
        full_weight = role in ('DPS', 'WS') and row['latentId'] in DD_ALWAYS_LATENTS
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
# SMN sachets — forced AMMO picks (owner request 2026-06-14).
# These five SMN-only avatar items (Eminent / Dashavatara / Arasy / Sancus /
# Sancus +1) carry avatar/Blood-Pact mods (AVATAR_LVL_BONUS, BP_DELAY[_II]),
# so they score well under the new PET role — BUT they live in the AMMO slot
# (slot bitmask 8) with itype @WEAPON_TYPE, so the normal candidate loop drops
# them on BOTH the SLOT_NAMES check and the @EQUIPMENT_TYPE check. We surface
# them anyway by scoring them directly off the DB (same as the Sortie earrings)
# and emitting them into the Accessory NPC's AMMO slot. Sancus Sachet +1
# (21395) is the BiS -> gold; the rest -> silver. {id: tier}.
SACHET_AMMO_TIER = {
    21395: 'gold',     # sancus_sachet_+1  (BiS)
    21394: 'silver',   # sancus_sachet
    21393: 'silver',   # arasy_sachet
    21388: 'silver',   # dashavatara_sachet
    21383: 'silver',   # eminent_sachet
}
SACHET_IDS = set(SACHET_AMMO_TIER)


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
        best_role = next((r for r in ('DPS', 'TANK', 'CASTER', 'HEAL', 'WS', 'PET')
                          if e['jobs'] & ROLE_MASKS[r]), 'DPS')
        best_score = 0.0
    sortie_earrings.append({
        'id': iid, 'name': info['name'], 'jobs': e['jobs'],
        'role': best_role, 'score': best_score,
    })
print(f"Sortie JSE +2 earrings for Infamy override: {len(sortie_earrings)}")


# ----------------------------------------------------------------------------
# SMN sachets — build full candidate-shaped rows (forced into the WAIST slot).
# They're dropped by the candidate loop (ammo slot + @WEAPON_TYPE), so score
# them directly here. Injected into the bronze/silver/gold waist buckets after
# role-balanced selection so they're guaranteed to appear for SMN.
# ----------------------------------------------------------------------------
sachet_rows: list[dict] = []
for iid, tier in SACHET_AMMO_TIER.items():
    info = items_base.get(iid)
    e = equip.get(iid)
    if not info or not e:
        print(f"  [SACHET] WARN: id {iid} not found in item_basic/item_equipment — skipped")
        continue
    per = {}
    for role in ROLE_WEIGHTS:
        if (e['jobs'] & ROLE_MASKS[role]) == 0:
            continue
        sc = score_item(iid, role)
        if sc > 0:
            per[role] = sc
    if not per:
        # No weighted mod hit — still surface it under PET so SMN can buy it.
        per = {'PET': 0.0}
    sachet_rows.append({
        'id':      iid,
        'name':    info['name'],
        'slot':    'ammo',
        'jobs':    e['jobs'],
        'ilevel':  e['ilevel'],
        'level':   e['level'],
        'is_rare': info['is_rare'],
        'is_ex':   info['is_ex'],
        'roles':   per,
        'ceiling': max(per.values()),
        'tier':    tier,
    })
print(f"SMN sachets forced into ammo: {len(sachet_rows)}")


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


# Owner exclusivity: mark obtainable-elsewhere accessories with a sentinel tier so
# every selection path (incl. the per-slot pools that share these dicts) skips them
# in bronze/silver/gold (Infamy skim exempt).
_excl_n = 0
for c in candidates:
    if c['tier'] != 'infamy' and c['id'] in OBTAINABLE_ELSEWHERE:
        c['tier'] = '_excluded'
        _excl_n += 1
print(f"Vendor-exclusive filter: removed {_excl_n} obtainable-elsewhere accessories from bronze/silver/gold")

tier_slot_count = Counter((c['tier'], c['slot']) for c in candidates)
print("\nPiece counts by tier x slot:")
for tier in ('bronze', 'silver', 'gold'):
    row = "  " + tier.capitalize().ljust(8)
    for slot in ('neck', 'waist', 'ear', 'ring', 'back', 'ammo'):
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
    roles = ['DPS', 'TANK', 'CASTER', 'HEAL', 'WS', 'PET']
    # cursor keyed by the full role list (not just roles present in this pool)
    # so an empty/partial pool -- e.g. the curated-only 'ammo' slot whose
    # candidate pool is empty -- can't KeyError on cursor[role] below.
    cursor = {role: 0 for role in roles}
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
    for slot in ('neck', 'waist', 'ear', 'ring', 'back', 'ammo'):
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


# ----------------------------------------------------------------------------
# Inject the SMN sachets into their tier's AMMO bucket (forced — they can't
# flow through the scored candidate pool because they're ammo-slot/@WEAPON_TYPE
# items). Prepended so they surface at the top of the ammo list for SMN, and
# id-deduped so a re-run can't double them.
# ----------------------------------------------------------------------------
for sr in sachet_rows:
    key = (sr['tier'], 'ammo')
    existing = buckets.get(key, [])
    if any(c['id'] == sr['id'] for c in existing):
        continue
    buckets[key] = [sr] + existing


# ============================================================================
# Pretty print top picks
# ============================================================================
print("\nTop picks per (tier, slot):\n")
for tier in ('bronze', 'silver', 'gold'):
    print(f"=== {tier.upper()} (cost {TIER_COST[tier]} medals) ===")
    for slot in ('neck', 'waist', 'ear', 'ring', 'back', 'ammo'):
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
    "--   Lines up with the Armor / Weapons NPCs and the Hunting League hub",
    "--   on the Escha - Zi'Tah vendor row (z = -30), so all gear vendors are",
    "--   in one place and players don't zone-hop.",
    "-----------------------------------",
    "catalog.zoneId    = xi.zone.ESCHA_ZITAH",
    "catalog.zonePath  = 'xi.zones.Escha_ZiTah'",
    "catalog.vendorPos = { x = -9.0000, y = -0.5000, z = -30.0000, rot = 128 }",
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
    "    return { neck = {}, waist = {}, ear = {}, ring = {}, back = {}, ammo = {} }",
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
    for slot in ('neck', 'waist', 'ear', 'ring', 'back', 'ammo'):
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
for slot in ('neck', 'waist', 'ear', 'ring', 'back', 'ammo'):
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
