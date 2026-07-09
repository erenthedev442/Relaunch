"""Score armor pieces by stat value per role, bucket into Bronze/Silver/Gold.

Reads:
    sql/item_basic.sql       (name + RARE flag)
    sql/item_equipment.sql   (level, ilevel, jobs bitfield, slot)
    sql/item_mods.sql        (always-on stat bonuses)
    sql/item_latents.sql     (conditional mods — applied at 50% weight)

For each ilvl >= 119 main-armor piece (Head/Body/Hands/Legs/Feet), computes
a score under each role weight map (DPS / WS / Tank / Caster / Heal),
gated by whether the piece is equippable by any job in that role. The
piece's "ceiling" is its highest per-role score; ceiling determines the
tier bucket via 33rd / 66th percentile thresholds.

Outputs (printed):
    1. Counts per (tier, slot)
    2. Top N picks per (tier, slot)
    3. A Lua snippet ready to paste into armor_catalog.lua

Re-run any time the DB or weight maps change.
"""
from __future__ import annotations

import re
from collections import Counter, defaultdict
from pathlib import Path

import os
ROOT = Path(os.environ.get("SCORE_ROOT", r"D:/server"))

# NPC-only / non-player junk to keep OUT of the scored vendor catalogs. Mirror
# of the list in tools/docgen/generators/gear_finder.py (and the DB purge in
# modules/custom/sql/zz_remove_judge_items.sql). Excluded by id AND name prefix
# so a re-import can't slip them back in. Keep these copies in sync.
EXCLUDED_ITEM_IDS = frozenset({
    12332, 12523, 12551, 12679, 12807, 12935, 13074, 13215, 13358, 13505,
    13606, 16622, 17004, 17012, 17174, 17326, 17406, 17644, 19325,  # Judge* (Ballista)
})
EXCLUDED_NAME_PREFIXES = ('judge',)

# Owner suppressions: gameplay items kept OUT of every tier. 2026-06-13:
# Argosy Hauberk base (26848) dropped -- its +1 (26849) is pinned to bronze
# via FORCED_INCLUDE, so the base in silver was redundant (and made the +1
# both better AND cheaper than the base).
OWNER_EXCLUDE_IDS = frozenset({26848})

# Owner exclusivity rule (2026-07): the medal vendor's bronze/silver/gold tiers may
# ONLY sell gear that is EXCLUSIVE to it. Any ilvl119+ piece obtainable elsewhere
# (mob drops, crafting, or another custom content/vendor/forge catalog) is dropped
# from those tiers. The id set is built by tools/gen_vendor_exclusions.py.
# FORCED_INCLUDE picks and the Infamy skim are exempt.
import json as _json
_excl_path = Path(__file__).with_name('vendor_obtainable_elsewhere.json')
OBTAINABLE_ELSEWHERE = (frozenset(_json.loads(_excl_path.read_text(encoding='utf-8'))['ids'])
                        if _excl_path.exists() else frozenset())


# --------------------------------------------------------------
# Parsing helpers
# --------------------------------------------------------------
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


# --------------------------------------------------------------
# 1. item_basic — name + RARE
# --------------------------------------------------------------
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
        if iid in OWNER_EXCLUDE_IDS:
            continue  # owner-suppressed (e.g. a base superseded by a +N pinned elsewhere)
        flags = fields[7]
        items_base[iid] = {
            'name':    fields[2].strip("'"),
            'is_rare': '@FLAG_RARE' in flags,
        }

# --------------------------------------------------------------
# 2. item_equipment — level, ilevel, jobs, slot
# --------------------------------------------------------------
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

# --------------------------------------------------------------
# 3. item_mods — always-on stat bonuses.
# Loaded in TWO passes that mirror dbtool's load order:
#   (a) sql/item_mods.sql                 — upstream LSB base
#   (b) sql/zz_custom_naked_item_mods.sql — locally-generated BG-Wiki
#       stats for the ~1400 "naked" items the upstream DB hadn't
#       implemented yet (Reforge +3/+4, JSE +1/+2/+3, Su5 sets, etc.)
# The custom file uses ON DUPLICATE KEY UPDATE semantics. We mirror
# that by replacing any (itemid, modId) collision with the custom
# value via a dict keyed on (itemid, modId), then flattening to the
# list-of-tuples shape the scorer expects. Without this layered read,
# every +4 item scores 0 here (no mods) and gets filtered out of the
# candidate pool entirely — which is exactly the bug that motivated
# this comment block.
from _item_mods import load_item_mod_map
# Merge EVERY item_mods source (base + all zz_ overlays + tier carry-forward),
# not just item_mods.sql + zz_custom_naked -- otherwise reforge/relic/Tokko gear
# and the carry-forward fixes are under-read and mis-scored.
_item_mod_map = load_item_mod_map(ROOT / 'sql')

item_mods: dict[int, list[tuple[int, int]]] = defaultdict(list)
for (iid, mid), val in _item_mod_map.items():
    item_mods[iid].append((mid, val))

# --------------------------------------------------------------
# 4. item_latents — conditional mods (50% weight by default)
# --------------------------------------------------------------
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


# --------------------------------------------------------------
# 5. Job bit map + roles
# --------------------------------------------------------------
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
    # PET role: pet/avatar gear is SMN's real BiS and never scored under
    # CASTER (which only rewards nuke stats), so SMN pet pieces scored ~0
    # and never got picked. BST/PUP share the same pet-stat mods.
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


# --------------------------------------------------------------
# 6. Build the candidate set
# --------------------------------------------------------------
SLOT_NAMES = {16: 'head', 32: 'body', 64: 'hands', 128: 'legs', 256: 'feet', 2: 'shields'}

candidates: list[dict] = []
for iid, info in items_base.items():
    # NOTE: RARE is intentionally NOT excluded here. Unlike catalysts (which
    # players need to stockpile), armor slots only need ONE of a piece — so
    # RARE items like Nyame Mail / Sakpata's / Malignance are perfectly fine
    # as vendor rewards.
    e = equip.get(iid)
    if not e:
        continue
    if e['ilevel'] < 119:
        continue
    if e['slot'] not in SLOT_NAMES:
        continue
    if not item_mods.get(iid) and not item_latents.get(iid):
        continue
    # Multi-job filter: single-job pieces (AF / Relic / Empyrean reforged)
    # belong in the Reforged System catalog, not this Armor Vendor. Keep
    # only items equippable by 2+ jobs so the Armor Vendor stays focused
    # on universal-utility gear that crosses jobs. EXCEPTION: shields (slot
    # 2) are inherently job-specific (most tank shields are PLD-only), so
    # single-job shields are kept -- they have nowhere else to go.
    if bin(e['jobs']).count('1') < 2 and e['slot'] != 2:
        continue
    # Explicit +4 exclusion (belt-and-suspenders on top of the multi-job
    # filter above). +4 reforge sets are an Infamy Vendor exclusive (see
    # modules/custom/lua/dungeon_catalog.lua catalog.plus4Sets). Even if
    # the multi-job rule gets relaxed for some future tweak, this line
    # keeps +4 pieces out of the regular Armor Vendor catalog. Mirrored
    # in tools/score_weapons.py.
    if items_base[iid]['name'].endswith('_+4'):
        continue

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
        'id':     iid,
        'name':   info['name'],
        'slot':   SLOT_NAMES[e['slot']],
        'jobs':   e['jobs'],
        'ilevel': e['ilevel'],
        'roles':  per_role,
        'ceiling': ceiling,
    })

print(f"Viable ilvl>=119 armor candidates: {len(candidates)}")

# id -> candidate lookup, used by the owner-forced bucket additions (FORCED_INCLUDE).
_cand_by_id = {c['id']: c for c in candidates}


# --------------------------------------------------------------
# 7. Tier bucketing: FIXED score bands + top-5-per-slot Infamy skim
#    (replaces the old 33rd/66th percentile split — owner request
#     2026-06-05). The bands apply to armor AND weapons identically:
#       Bronze   ceiling <= 200
#       Silver   201 .. 250
#       Gold     251+              (open-topped)
#    Then the 5 highest-scoring pieces per slot (family-deduped, so a
#    piece and its +1/+2 collapse to a single Infamy slot) are skimmed
#    OUT of the gear vendor into an Infamy-exclusive tier. Those are
#    promoted to the Dungeon Infamy Vendor by
#    tools/build_infamy_top_picks.py — "the best options in game."
#    catalog.infamy is inert for the Armor NPC (it only reads
#    bronze/silver/gold) and for docgen (only binds those three tiers).
# --------------------------------------------------------------
BRONZE_MAX, SILVER_MAX = 200, 250
INFAMY_TOP_PER_SLOT = 5

# Tiny inline family roll-up (the full dedup_by_family is defined lower,
# AFTER this block runs at import time). Strips a trailing ' +N'.
_inf_fam_re = re.compile(r"\s*\+\d+\s*$")
def _inf_family(nm: str) -> str:
    return _inf_fam_re.sub("", nm.replace("_", " ")).strip()
def _inf_rank(nm: str) -> int:
    mm = re.search(r"\+(\d+)\s*$", nm.replace("_", " "))
    return int(mm.group(1)) if mm else 0

infamy_ids: set[int] = set()
for _slot in SLOT_NAMES.values():
    _best: dict[str, dict] = {}
    for c in (x for x in candidates if x['slot'] == _slot):
        fam = _inf_family(c['name'])
        cur = _best.get(fam)
        if (cur is None
                or _inf_rank(c['name']) > _inf_rank(cur['name'])
                or (_inf_rank(c['name']) == _inf_rank(cur['name'])
                    and c['ceiling'] > cur['ceiling'])):
            _best[fam] = c
    for c in sorted(_best.values(), key=lambda x: -x['ceiling'])[:INFAMY_TOP_PER_SLOT]:
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

# Shields carry few stat mods (mostly DEF), so the fixed score bands above
# would dump every non-Infamy shield into Bronze. Re-tier the shield pool by
# score RANK so the best shields reach Gold/Silver and the vendor offers
# shields across all four tiers (the Infamy top-5 skim already took the cream).
_shields = sorted((c for c in candidates
                   if c['slot'] == 'shields' and c['id'] not in infamy_ids),
                  key=lambda x: -x['ceiling'])
_ns = len(_shields)
for _i, _c in enumerate(_shields):
    if   _i < _ns / 3:     _c['tier'] = 'gold'
    elif _i < 2 * _ns / 3: _c['tier'] = 'silver'
    else:                  _c['tier'] = 'bronze'

print(f"Tier bands: Bronze<=200 | Silver 201-250 | Gold 251+ | "
      f"Infamy = top {INFAMY_TOP_PER_SLOT}/slot ({len(infamy_ids)} pieces -> Infamy Vendor)")


# --------------------------------------------------------------
# 8. Pretty-print summary + top-N per (tier, slot)
# --------------------------------------------------------------
tier_slot_count = Counter((c['tier'], c['slot']) for c in candidates)
print("\nPiece counts by tier x slot:")
for tier in ('bronze', 'silver', 'gold'):
    row = "  " + tier.capitalize().ljust(8)
    for slot in ('head', 'body', 'hands', 'legs', 'feet', 'shields'):
        row += f"{slot}:{tier_slot_count[(tier, slot)]:>4}  "
    print(row)


def js_jobs(bits: int) -> str:
    inv = {v: k for k, v in JOB.items()}
    names = [inv[b] for b in inv if (bits & b)]
    return '/'.join(names) if names else '?'


# --------------------------------------------------------------
# 9. Emit a Lua catalog block
# --------------------------------------------------------------
# Medal cost per gear-vendor tier. 'infamy' here is cosmetic only — those
# rows live in catalog.infamy and the REAL Infamy price is assigned by
# tools/build_infamy_top_picks.py when it writes catalog.vendorItemsAuto.
TIER_COST = {'bronze': 12, 'silver': 25, 'gold': 50, 'infamy': 500}

# Owner-forced bucket additions: item ids guaranteed to appear in a given
# (tier, slot) regardless of their computed score band. These pieces score
# into silver/gold naturally; pinning them at bronze is a deliberate
# accessibility choice -- here, seeding bronze BODY with melee/tank options
# (the auto-scored bronze body was caster/heal-only). Added 2026-06-13.
# NOTE: a forced item is NOT removed from any higher tier it also auto-selects
# into, so check for cross-tier family overlap when adding ids here.
FORCED_INCLUDE = {
    ('bronze', 'body'): [25790, 26849, 25683, 25780, 25702, 25686, 26870, 25684],  # 26536 Pinga Tunic +1 removed 2026-07 (craft / Invasion loot -- vendor exclusivity)
    ('silver', 'body'): [25717, 25796, 25752],  # +25752 Inyanga Jubbah +1 -- completes the Inyanga caster set (2026-06-21)
    ('gold',   'body'): [23733, 23766, 23763],  # 2026-07 removed 26943 Agony Jerkin +1 (Unity/Voso drop) + 26530 Ea Houppelande +1 (craft/Invasion). +23763 Gletis Cuirass -- Gleti (Sortie) set
    ('gold',   'feet'): [23736],  # Malignance Boots -- pin to gold so the full Malignance gold set is buyable (it scores just under gold's cut). Added 2026-06-14. (Gletis Boots 23784 already auto-scores into gold/feet.)
    ('gold',   'hands'): [23770, 23734],  # 23770 Gletis Gauntlets -- Gleti (Sortie) set (owner request 2026-06-21). +23734 Malignance Gloves -- completes the Malignance gold set (was missing from ANY vendor; player report 2026-07-08).
    ('gold',   'head'): [23732, 25575, 23756],  # 2026-07 removed 25554 Ea Hat +1 (craft/Invasion). 23732 Malignance Chapeau + 25575 Meghanada Visor +2 + 23756 Gletis Mask
    ('gold',   'legs'): [23735],  # 2026-07 removed 25894 Ea Slops +1 (craft/Invasion). 23735 Malignance Tights completes its set. (Gletis Breeches 23777 is NAKED -- not pinned.)
    # ---- 2026-06-21: two near-finished sets that need a NEW (tier, slot) key ----
    ('silver', 'head'): [25616, 25579],  # 25616 Amalric Coif +1 (completes Amalric); 25579 Flamma Zucchetto re-pinned -- forcing the Amalric caster head bumped this tank head from the per-job top-N, which would have broken the otherwise-complete Flamma set
    ('silver', 'legs'): [25874],  # Flamma Dirs +1  -- completes the bronze/silver Flamma melee set
    # Taliah +2 set (BST/SMN/PUP): pin hands/feet/body +2 to silver alongside
    # the auto-scored Turban +2 (head) and Seraweels +2 (legs) so the full
    # 5-piece +2 set is buyable from the one Kindreds Medal tier. These three
    # +2 pieces score into the gold band but don't survive gold's top-N, so
    # unpinned only their +1 (hands/feet) or nothing (body) appears. The family
    # roll-up then drops the now-redundant +1 from silver automatically.
    ('silver', 'hands'): [25834],  # Taliah Gages +2    (replaces Gages +1)
    ('silver', 'feet'):  [25952],  # Taliah Crackows +2 (replaces Crackows +1)
    #   ('silver', 'body') above also gains 25796 = Taliah Manteel +2
}

# Pin each forced item to its tier and pull it out of whatever tier it would
# otherwise auto-select into, so a forced item never shows up in two tiers.
_forced_tier = {iid: t for (t, _slot), ids in FORCED_INCLUDE.items() for iid in ids}
for _c in candidates:
    if _c['id'] in _forced_tier:
        _c['tier'] = _forced_tier[_c['id']]

# Owner exclusivity: mark obtainable-elsewhere gear with a sentinel tier so every
# selection path (candidates list AND per-slot pools that share these dicts) skips
# it in bronze/silver/gold. Infamy and explicit FORCED_INCLUDE picks are exempt.
_excl_n = 0
for _c in candidates:
    if _c['tier'] != 'infamy' and _c['id'] not in _forced_tier and _c['id'] in OBTAINABLE_ELSEWHERE:
        _c['tier'] = '_excluded'
        _excl_n += 1
print(f"Vendor-exclusive filter: removed {_excl_n} obtainable-elsewhere pieces from bronze/silver/gold")

# Starting size of each (tier, slot) bucket from role-balanced selection.
# This is the FLOOR — the per-job coverage pass below may expand a bucket
# further to guarantee MIN_PER_JOB options for every job.
TOP_PER_BUCKET = 10

# Every (tier, slot) must offer at least this many items each of the 22
# jobs can equip. If a job has fewer after role-balanced selection, the
# bucket is expanded with next-best-by-ceiling picks the job can wear.
MIN_PER_JOB = 2


# --------------------------------------------------------------
# Family roll-up: keep only the highest-rank version of each item
# family in any given (tier, slot). Prevents the picker from
# selecting Mallquis Chapeau, Mallquis Chapeau +1, AND Mallquis
# Chapeau +2 all in the same tier — the +2 always strictly beats
# the lower ranks, so picking all three wastes vendor slots that
# could go to a different item family.
# --------------------------------------------------------------
_PLUS_SUFFIX_RE = re.compile(r"\s*\+\d+\s*$")


def base_family(name: str) -> str:
    """Strip a trailing ` +N` suffix to get the item's base family name.

    'Mallquis Chapeau +2' -> 'Mallquis Chapeau'
    'Mallquis Chapeau'    -> 'Mallquis Chapeau'
    """
    return _PLUS_SUFFIX_RE.sub("", name).strip()


def upgrade_rank(name: str) -> int:
    """Return the +N rank (0 for base, 1 for +1, etc.)."""
    m = re.search(r"\+(\d+)\s*$", name)
    return int(m.group(1)) if m else 0


def dedup_by_family(bucket: list[dict]) -> list[dict]:
    """Reduce a candidate list to one entry per family — the highest rank,
    tiebroken by ceiling score."""
    keep: dict[str, dict] = {}
    for c in bucket:
        family = base_family(c["name"].replace("_", " "))
        cur = keep.get(family)
        if cur is None:
            keep[family] = c
            continue
        cur_rank = upgrade_rank(cur["name"].replace("_", " "))
        new_rank = upgrade_rank(c["name"].replace("_", " "))
        if new_rank > cur_rank:
            keep[family] = c
        elif new_rank == cur_rank and c["ceiling"] > cur["ceiling"]:
            keep[family] = c
    return list(keep.values())

# --------------------------------------------------------------
# 9. Write a populated armor_catalog.lua by patching the
#    existing file in place (preserving header, seals, zone, etc.)
# --------------------------------------------------------------
catalog_path = ROOT / 'modules' / 'custom' / 'lua' / 'armor_catalog.lua'
original = catalog_path.read_text(encoding='utf-8', errors='replace')

# Replace from the FIRST auto-gen header through "return catalog". If the
# header is missing (first run), fall back to catalog.bronze line. Matching
# the header lets us clean up duplicates accumulated by older versions of
# this script that started replacement at catalog.bronze, leaving stale
# header copies behind.
m_header = re.search(
    r"^-{10,}\s*\n-- TIER CONTENTS\b.*?(?=^catalog\.bronze\s*=\s*emptySlots)",
    original,
    re.MULTILINE | re.DOTALL,
)
m_start = m_header or re.search(
    r"^catalog\.bronze\s*=\s*emptySlots\(\)\s*$", original, re.MULTILINE
)
m_end   = re.search(r"^return\s+catalog\s*$", original, re.MULTILINE)
assert m_start and m_end, (
    "couldn't locate TIER CONTENTS header / catalog.bronze / return catalog in armor_catalog.lua"
)

before = original[:m_start.start()]
after  = original[m_end.start():]   # keep "return catalog"

# Track what each (tier, slot) ended up with so we can verify per-job
# coverage at the end without re-parsing the written file.
all_selected: dict[tuple[str, str], list[dict]] = {}


def select_bucket(tier_name: str, slot: str) -> list[dict]:
    """Pick items for one (tier, slot). Role-balanced + per-job backfill.

    Stages:
      1. Filter to (tier, slot) candidates, dedupe upgrade families.
      2. Take top picks per role (DPS/WS/TANK/CASTER/HEAL) — preserves
         representation so a stat-heavy role doesn't crowd others out.
      3. If still under TOP_PER_BUCKET, pad with next-best by ceiling.
      4. Per-job backfill: for any of the 22 jobs with fewer than
         MIN_PER_JOB equippable picks, pull next-best-by-ceiling items
         the job can wear. Expands the bucket past TOP_PER_BUCKET if
         needed — the per-job guarantee wins over the soft cap.
    """
    bucket = [c for c in candidates if c['tier'] == tier_name and c['slot'] == slot]
    bucket = dedup_by_family(bucket)

    selected: dict[int, dict] = {}

    # Stage 2: role-balanced top picks
    per_role_top = max(2, TOP_PER_BUCKET // len(ROLE_WEIGHTS))   # 2-3 per role
    for role in ROLE_WEIGHTS:
        role_picks = sorted(
            (c for c in bucket if role in c['roles']),
            key=lambda x: -x['roles'][role],
        )[:per_role_top]
        for c in role_picks:
            selected.setdefault(c['id'], c)

    # Stage 3: pad to TOP_PER_BUCKET if underfilled
    if len(selected) < TOP_PER_BUCKET:
        for c in sorted(bucket, key=lambda x: -x['ceiling']):
            if c['id'] not in selected:
                selected[c['id']] = c
                if len(selected) >= TOP_PER_BUCKET:
                    break

    # Stage 4: per-job coverage backfill
    for jname, jbit in JOB.items():
        cur_count = sum(1 for c in selected.values() if c['jobs'] & jbit)
        need = MIN_PER_JOB - cur_count
        if need <= 0:
            continue
        for c in sorted(
            (c for c in bucket if (c['jobs'] & jbit) and c['id'] not in selected),
            key=lambda x: -x['ceiling'],
        )[:need]:
            selected[c['id']] = c

    return sorted(selected.values(), key=lambda x: -x['ceiling'])


def tier_block(tier_name: str, var: str) -> str:
    lines = [f"catalog.{tier_name} = emptySlots()", f"local {var} = catalog.{tier_name}", ""]
    for slot in ('head', 'body', 'hands', 'legs', 'feet', 'shields'):
        rows = select_bucket(tier_name, slot)
        # Owner-forced additions: guaranteed present in this (tier, slot)
        # regardless of score band (see FORCED_INCLUDE).
        for fid in FORCED_INCLUDE.get((tier_name, slot), []):
            if any(r['id'] == fid for r in rows):
                continue
            fc = _cand_by_id.get(fid)
            if fc:
                rows.append(fc)
            else:
                print(f"  [FORCED_INCLUDE] WARN: id {fid} not in scored pool "
                      f"(no DB mods / <iL119 / single-job?) -- NOT added to {tier_name}/{slot}")
        rows = sorted(rows, key=lambda x: -x['ceiling'])
        all_selected[(tier_name, slot)] = rows
        if not rows:
            continue
        lines.append(f"-- {slot.capitalize()} ({len(rows)} picks, scored highest first)")
        for c in rows:
            cost = TIER_COST[tier_name]
            name = c['name'].replace('_', ' ').title().replace("'S", "'s")
            jobs = js_jobs(c['jobs'])
            best_role = max(c['roles'], key=c['roles'].get)
            score = c['roles'][best_role]
            lines.append(
                f"table.insert({var}.{slot}, "
                f"{{ id = {c['id']}, name = \"{name}\", cost = {cost}, "
                f"jobs = '{jobs}' }})  -- {best_role} score {score:.0f}"
            )
        lines.append("")
    return "\n".join(lines)


def infamy_block(var: str) -> str:
    """Emit catalog.infamy — exactly the top-5-per-slot pieces skimmed
    above (tier == 'infamy'), highest score first. Same row shape as the
    gear tiers so tools/build_infamy_top_picks.py can parse the score
    comment. NOT routed through select_bucket: no role-balancing or
    per-job padding — the Infamy tier is the raw top-5 per slot."""
    lines = ["catalog.infamy = emptySlots()", f"local {var} = catalog.infamy", ""]
    for slot in ('head', 'body', 'hands', 'legs', 'feet', 'shields'):
        rows = sorted(
            (c for c in candidates if c['tier'] == 'infamy' and c['slot'] == slot),
            key=lambda x: -x['ceiling'],
        )
        all_selected[('infamy', slot)] = rows
        if not rows:
            continue
        lines.append(f"-- {slot.capitalize()} (top {len(rows)} by score -> Infamy Vendor)")
        for c in rows:
            name = c['name'].replace('_', ' ').title().replace("'S", "'s")
            jobs = js_jobs(c['jobs'])
            best_role = max(c['roles'], key=c['roles'].get)
            score = c['roles'][best_role]
            lines.append(
                f"table.insert({var}.{slot}, "
                f"{{ id = {c['id']}, name = \"{name}\", cost = {TIER_COST['infamy']}, "
                f"jobs = '{jobs}' }})  -- {best_role} score {score:.0f}"
            )
        lines.append("")
    return "\n".join(lines)


new_middle = []
new_middle.append("-----------------------------------")
new_middle.append("-- TIER CONTENTS  (auto-generated by tools/score_armor.py)")
new_middle.append(f"--   Role-balanced top ~{TOP_PER_BUCKET} per tier-slot, expanded as needed")
new_middle.append(f"--   to guarantee >= {MIN_PER_JOB} options per job per (tier, slot).")
new_middle.append("--   To regenerate after edits to weights or new DB content:")
new_middle.append("--     python tools/score_armor.py")
new_middle.append("-----------------------------------\n")
new_middle.append("-- BRONZE TIER")
new_middle.append(tier_block('bronze', 'b'))
new_middle.append("\n-- SILVER TIER")
new_middle.append(tier_block('silver', 's'))
new_middle.append("\n-- GOLD TIER")
new_middle.append(tier_block('gold', 'g'))
new_middle.append("\n-- INFAMY TIER  (top-5-per-slot; promoted to the Dungeon Infamy")
new_middle.append("--               Vendor by tools/build_infamy_top_picks.py. Inert here:")
new_middle.append("--               the Armor NPC only sells bronze/silver/gold.)")
new_middle.append(infamy_block('inf'))
new_middle.append("\n")

# Vendor placement is human-curated; scoring is advisory (recommendation tool only).
# The catalog is NOT overwritten unless you explicitly re-seed from scores. [decoupled 2026-07]
_wrote = bool(os.environ.get("WRITE_VENDOR_CATALOG"))
if _wrote:
    catalog_path.write_text(before + "\n".join(new_middle) + after, encoding='utf-8', newline='\n')

# Final summary
total = sum(len(rows) for rows in all_selected.values())
if _wrote:
    print(f"\nWrote {catalog_path}")
else:
    print(f"\n[scoring-only] {catalog_path.name} left untouched -- vendor placement is human-curated.")
    print(f"               Scores above feed the gear recommendation tool only.")
    print(f"               Re-seed a catalog from scores only with WRITE_VENDOR_CATALOG=1.")
print(f"Total items in catalog: {total}")
print(f"  ({len(all_selected)} buckets, MIN_PER_JOB={MIN_PER_JOB}, soft floor TOP_PER_BUCKET={TOP_PER_BUCKET})")

print("\nBucket sizes (tier x slot):")
for tier in ('bronze', 'silver', 'gold'):
    row = "  " + tier.capitalize().ljust(8)
    for slot in ('head', 'body', 'hands', 'legs', 'feet', 'shields'):
        row += f"{slot}:{len(all_selected.get((tier, slot), [])):>3}  "
    print(row)

# Per-job coverage verification. Any cell below MIN_PER_JOB means the DB
# genuinely doesn't have that many ilvl>=119 multi-job pieces for that
# (tier, slot, job) — we can't synthesize items that don't exist.
gaps: list[tuple[str, str, str, int]] = []
for tier in ('bronze', 'silver', 'gold'):
    for slot in ('head', 'body', 'hands', 'legs', 'feet'):
        rows = all_selected.get((tier, slot), [])
        for jname, jbit in JOB.items():
            n = sum(1 for c in rows if c['jobs'] & jbit)
            if n < MIN_PER_JOB:
                gaps.append((tier, slot, jname, n))

print()
if gaps:
    print(f"GAPS: {len(gaps)} (tier, slot, job) cells below MIN_PER_JOB={MIN_PER_JOB}:")
    for tier, slot, jname, n in gaps:
        print(f"  {tier:>6} / {slot:<5} / {jname}: {n} option(s)  "
              f"(DB has no more equippable {slot} items at that tier)")
else:
    print(f"OK: every job has >= {MIN_PER_JOB} options in every (tier, slot).")
