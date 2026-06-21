"""Generate the Gear Finder dataset (docs/assets/gear-data.json).

The Gear Finder page (docs/progression/gear-finder.md) is an interactive,
client-side tool: a searchable/sortable database of every equippable item
on the server PLUS a job-driven "best in slot" set builder. All the heavy
lifting happens in the browser (docs/assets/gear-finder.js); this generator
just produces the compact JSON it consumes.

Sources (read via resolve_source, so live state wins over the repo copy):
  - sql/item_equipment.sql              every equippable item (slot/jobs/lvl/ilvl/su)
  - sql/item_basic.sql                  display name flags (Ex / Rare)
  - sql/item_mods.sql                   stats
  - sql/zz_custom_naked_item_mods.sql   our custom + derived stats
  - sql/item_weapon.sql                 skill / dmg / delay (weapons)
  - sql/item_latents.sql               latent stats
  - scripts/enum/mod.lua                mod id -> readable label

Obtainability: after the source pages have been (re)generated, we scan them
for `item-link` anchors and mark the matching item ids as obtainable, with a
short source label. This lets the tool offer an "obtainable on Legendary"
filter on top of the full DB.

The role-balance scores (DD / Tank / Caster / Heal) are computed with the
EXACT same weights/formula as tools/score_*.py and build_items_spreadsheet.py,
so the set builder's recommendations line up with the scored catalogs.
"""
from __future__ import annotations

import json
import re
import time
from collections import defaultdict
from pathlib import Path

from tools.docgen._paths import resolve_source

# ---------------------------------------------------------------------------
# Static maps
# ---------------------------------------------------------------------------

# Job bit order (bit 0 = WAR ... bit 21 = RUN). Matches item_equipment.jobs.
JOBS = ['WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD',
        'RNG', 'SAM', 'NIN', 'DRG', 'SMN', 'BLU', 'COR', 'PUP', 'DNC', 'SCH',
        'GEO', 'RUN']
JOB_BIT = {j: 1 << i for i, j in enumerate(JOBS)}

# Equip-slot bit -> short slot name. item_equipment.slot is a bitmask; most
# items occupy one slot, ear/ring items set both L+R bits.
SLOT_BITS = [
    (0, 'Main'), (1, 'Sub'), (2, 'Range'), (3, 'Ammo'),
    (4, 'Head'), (5, 'Body'), (6, 'Hands'), (7, 'Legs'), (8, 'Feet'),
    (9, 'Neck'), (10, 'Waist'), (11, 'Ear'), (12, 'Ear'),
    (13, 'Ring'), (14, 'Ring'), (15, 'Back'),
]
# Canonical slot list (collapsed L/R) in equip order, for the UI.
SLOT_ORDER = ['Main', 'Sub', 'Range', 'Ammo', 'Head', 'Neck', 'Ear',
              'Body', 'Hands', 'Ring', 'Back', 'Waist', 'Legs', 'Feet']

# item_weapon.skill -> weapon type label (only weapon-relevant skills).
WEAPON_SKILLS = {
    1: 'Hand-to-Hand', 2: 'Dagger', 3: 'Sword', 4: 'Great Sword', 5: 'Axe',
    6: 'Great Axe', 7: 'Scythe', 8: 'Polearm', 9: 'Katana', 10: 'Great Katana',
    11: 'Club', 12: 'Staff', 25: 'Archery', 26: 'Marksmanship', 27: 'Throwing',
    40: 'Singing', 41: 'String', 42: 'Wind', 45: 'Handbell',
}

# ---------------------------------------------------------------------------
# NPC-only / non-player junk — NEVER list these in the Gear Finder.
# These rows live in item_equipment (so they're technically equippable) but are
# NPC or event gear that no player can obtain or use; listing them just pollutes
# the database with nonsense scores ("Judge's Cape 1100 DPS"). Excluded by id AND
# by name prefix, so every variant is caught even if a re-import shifts ids.
#   - Judge* : the Ballista referee NPC's gear + fishing bait. Also hard-deleted
#              from the DB by modules/custom/sql/zz_remove_judge_items.sql; this
#              keeps them out of the Finder even if that delete isn't re-applied.
# Add more ids / prefixes here as you spot NPC-only junk in the Finder.
# ---------------------------------------------------------------------------
EXCLUDED_ITEM_IDS = frozenset({
    12332, 12523, 12551, 12679, 12807, 12935, 13074, 13215, 13358, 13505,
    13606, 16622, 17004, 17012, 17174, 17326, 17406, 17644, 19325,  # Judge* (Ballista)
})
# item_basic short-names (lowercase, underscored) starting with any of these are
# dropped too — a robust catch-all on top of the explicit id list above.
EXCLUDED_NAME_PREFIXES = ('judge',)

# ---------------------------------------------------------------------------
# Role-balance scoring  (kept identical to build_items_spreadsheet.py)
# ---------------------------------------------------------------------------
_DMG_JOBS = ['WAR', 'MNK', 'THF', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN',
             'DRG', 'BLU', 'COR', 'DNC', 'PUP', 'RUN']
ROLE_JOBS = {
    'DPS': _DMG_JOBS,   # sustained auto-attack
    'WS': _DMG_JOBS,    # weapon-skill burst (same jobs)
    'TANK': ['PLD', 'RUN', 'WAR', 'NIN'],
    'CASTER': ['BLM', 'SCH', 'GEO', 'SMN', 'RDM'],
    'HEAL': ['WHM', 'SCH', 'RDM', 'BRD', 'GEO'],
    'PET': ['SMN', 'BST', 'PUP'],   # SMN/BST/PUP pet/avatar gear (added 2026-06-14)
}
ROLE_MASKS = {r: sum(JOB_BIT[j] for j in js) for r, js in ROLE_JOBS.items()}
ROLE_WEIGHTS = {
    'DPS': {8: 2.0, 9: 2.0, 23: 1.0, 25: 1.5, 62: 5.0, 73: 2.0, 165: 4.0,
            259: 8.0, 288: 6.0, 302: 8.0, 384: 0.05, 289: 0.5, 387: -3.0, 421: 1.5,
            160: -0.03, 161: -0.03},                # all/phys dmg taken; /100 scale (neg = good)
    'WS': {8: 2.0, 9: 2.0, 23: 1.5, 25: 1.5,   # STR, DEX, ATT, ACC
           165: 2.0, 421: 3.0,                 # crit rate, crit damage
           345: 0.04,                          # TP_BONUS
           840: 5.0, 841: 3.0, 570: 1.0},      # WS damage mods (bumped — WSD% is premium for WS bursts)
    'TANK': {10: 2.0, 2: 0.5, 3: 3.0, 1: 1.0, 63: 3.0, 27: 3.0, 29: 3.0,
             387: -8.0, 389: -8.0,
             160: -0.06, 161: -0.06, 162: -0.04, 163: -0.06, 164: -0.04},  # dmg taken /100 (neg = good)
    'CASTER': {12: 2.0, 13: 1.0, 28: 3.0, 30: 2.0, 311: 4.0, 170: 2.0,
               5: 0.05, 6: 1.0,
               160: -0.03, 163: -0.03},             # all/magic dmg taken /100
    'HEAL': {13: 2.0, 14: 0.5, 5: 0.05, 6: 1.5, 369: 30.0, 374: 2.0,
             170: 2.0, 30: 1.0,
             160: -0.03, 163: -0.03},             # all/magic dmg taken /100
    'PET': {126: 4.0, 994: 3.0, 990: 1.5, 991: 1.5, 992: 1.5, 993: 1.5, 995: 1.0,
            117: 2.0, 346: 2.0, 357: 1.5, 541: 1.5, 1040: 5.0,
            5: 0.03, 6: 0.5},                    # SMN/BST/PUP pet/avatar: BP dmg, pet stats, summoning, perp, BP delay, avatar Lv
}
DD_ALWAYS_LATENTS = {7, 10, 41}
# Skills that are real melee/ranged weapons — only these get the DPS bonus, and
# only when slotted Main/Sub/Range with a sane delay. Keeps automaton ammo,
# instruments and pet food (which live in item_weapon with delay ~1) from
# producing absurd DPS scores.
COMBAT_SKILLS = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 25, 26, 27}
MOD_SANITY_CAP = {62: 30, 63: 30, 165: 20, 170: 30, 259: 15, 288: 20, 302: 20,
                  369: 10, 384: 300, 387: 30, 389: 30, 421: 30,
                  570: 50, 840: 50, 841: 50, 345: 500,
                  160: 5000, 161: 5000, 162: 5000, 163: 5000, 164: 5000}

# --- Player-specified additions: role assignments from the scoring workbook's
# "Unscored on gear" tab. Weights scaled to each mod's storage units:
#   506 EXTRA_DMG_CHANCE /10, 507 OCC_DO_EXTRA_DMG /100, 175 SKILLCHAINDMG /10000;
#   all others ~integer. All "higher is better" on gear (no sign flips).
_ADDED_WEIGHTS = {
    'DPS':    {11: 1.5, 506: 0.1, 507: 0.05, 368: 1.0, 361: 0.05, 362: 0.1,
               430: 8.0, 508: 0.1, 1039: 1.0, 432: 0.3, 954: 0.1, 113: 0.2},
    'WS':     {11: 1.5, 506: 0.1, 507: 0.05, 48: 1.0, 175: 0.01, 113: 0.2, 1144: 3.0, 949: 5.0},  # fTP bonus (Fotia) + WS no-deplete
    'TANK':   {68: 0.5, 31: 0.2, 370: 8.0, 110: 0.1, 168: 0.5, 291: 1.5,
               109: 0.3, 108: 0.5, 166: 1.0, 113: 0.2},
    'CASTER': {114: 0.5, 115: 0.5, 168: 0.5, 113: 0.2},
    'HEAL':   {168: 0.5, 112: 0.5, 519: 0.5, 113: 0.2},
    'PET':    {113: 0.2},   # shared baseline carried by every role
}
for _r, _w in _ADDED_WEIGHTS.items():
    ROLE_WEIGHTS[_r].update(_w)
MOD_SANITY_CAP.update({31: 300, 507: 300, 175: 2000, 361: 300, 430: 20, 1144: 100, 949: 10})
# PET-stat caps (added 2026-06-14) so a single outlier value can't dominate.
MOD_SANITY_CAP.update({126: 50, 990: 50, 991: 50, 992: 50, 993: 50, 994: 50,
                       995: 50, 117: 100, 346: 30, 357: 100, 541: 100, 1040: 10})

# Some mods are stored at x10/x100/x10000 of their in-game value (skillchain +7%
# is stored 700; PDT -10% is -1000; proc chance 13% is 130). Normalize to the
# human/BG-Wiki value so the tool + workbook show 7 / -10 / 13, not the raw
# numbers. Values are divided at read (below); weights are multiplied and caps
# divided here so role scores are mathematically unchanged.
MOD_SCALE = {160: 100, 161: 100, 162: 100, 163: 100, 164: 100,  # damage taken -> %
             175: 100,                                           # skillchain dmg -> %
             506: 10,                                            # proc chance -> %
             507: 100}                                           # occ-extra -> x multiplier
for _role in ROLE_WEIGHTS:
    for _m, _div in MOD_SCALE.items():
        if _m in ROLE_WEIGHTS[_role]:
            ROLE_WEIGHTS[_role][_m] *= _div
for _m, _div in MOD_SCALE.items():
    if _m in MOD_SANITY_CAP:
        MOD_SANITY_CAP[_m] = MOD_SANITY_CAP[_m] / _div


def _clamp(mid: int, val: int) -> int:
    cap = MOD_SANITY_CAP.get(mid, 200)
    return cap if val > cap else (-cap if val < -cap else val)


# Curated short labels for the most-used mods. Anything not here falls back to
# a prettified enum name from mod.lua, so every mod still gets a label.
# Every entry below is verified against scripts/enum/mod.lua (id -> enum name).
MOD_LABELS = {
    1: 'DEF', 2: 'HP', 3: 'HP%', 5: 'MP', 6: 'MP%',
    8: 'STR', 9: 'DEX', 10: 'VIT', 11: 'AGI', 12: 'INT', 13: 'MND', 14: 'CHR',
    23: 'Attack', 24: 'R.Attack', 25: 'Accuracy', 26: 'R.Accuracy',
    27: 'Enmity', 28: 'Magic Atk', 29: 'M.Def', 30: 'Magic Acc', 31: 'Magic Eva',
    62: 'Attack%', 63: 'DEF%', 73: 'Store TP', 345: 'TP Bonus',
    160: 'DT (all)', 161: 'PDT', 162: 'BDT', 163: 'MDT', 164: 'RDT',
    165: 'Crit Hit%', 169: 'Move Speed', 170: 'Fast Cast',
    173: 'Martial Arts',
    259: 'Dual Wield', 288: 'Double Attack', 289: 'Subtle Blow',
    302: 'Triple Attack', 311: 'Magic Dmg', 369: 'Refresh', 374: 'Cure Potency',
    384: 'Haste', 387: 'PDT (uncapped)', 389: 'MDT (uncapped)', 421: 'Crit Dmg',
    570: 'WS Dmg (1 WS)', 840: 'WS Dmg', 841: 'WS Dmg (1st)',
}


# ---------------------------------------------------------------------------
# Readable fallback labels for mods NOT in MOD_LABELS above.
#
# mod.lua enum names read like code (MEVA, FIRE_MACC, CONVMPTOHP). _pretty()
# turns them into human text. These maps do only MECHANICAL transforms --
# expanding well-known FFXI abbreviations, naming elements, fixing acronym
# casing -- so they assert no new mod meanings (re: the "verify vs mod.lua"
# rule, the dangerous part is the scoring weight table, not this display text).
# ---------------------------------------------------------------------------

# Whole enum names that aren't '_'-separated and need explicit spelling.
_PRETTY_WHOLE = {
    'CONVMPTOHP': 'Convert MP to HP', 'CONVHPTOMP': 'Convert HP to MP',
    'CRITHITRATE': 'Crit Hit Rate', 'FASTCAST': 'Fast Cast',
    'UFASTCAST': 'Fast Cast (uncapped)', 'STORETP': 'Store TP',
    'SNAPSHOT': 'Snapshot', 'SHARPSHOT': 'Sharpshot',
    'SHIELDBLOCKRATE': 'Shield Block Rate', 'SPELLINTERRUPT': 'Spell Interrupt Rate',
    'SKILLCHAINBONUS': 'Skillchain Bonus', 'SKILLCHAINDMG': 'Skillchain Dmg',
    'GAXE': 'Great Axe', 'GKATANA': 'Great Katana', 'GSWORD': 'Great Sword',
    'HTH': 'Hand-to-Hand', 'MPHEAL': 'Resting MP', 'HPHEAL': 'Resting HP',
    'WSACC': 'WS Acc.', 'RATTP': 'Ranged Atk.%', 'DEFP': 'Defense%',
    'DELAYP': 'Delay%', 'DMGPHYS': 'PDT', 'DMGMAGIC': 'MDT',
    'DMGBREATH': 'BDT', 'DMGRANGE': 'RDT',
    'UDMGPHYS': 'PDT (uncapped)', 'UDMGMAGIC': 'MDT (uncapped)',
    'UDMGBREATH': 'BDT (uncapped)', 'UDMGRANGE': 'RDT (uncapped)',
}

# Per-token expansions (applied to each '_'-separated piece of the enum name).
_PRETTY_TOKENS = {
    # elements (FFXI's THUNDER element displays in-game as "Lightning")
    'FIRE': 'Fire', 'ICE': 'Ice', 'WIND': 'Wind', 'EARTH': 'Earth',
    'THUNDER': 'Lightning', 'WATER': 'Water', 'LIGHT': 'Light', 'DARK': 'Dark',
    # magic stat abbreviations
    'MACC': 'Magic Acc.', 'MAB': 'Magic Atk.', 'MEVA': 'Magic Eva.',
    'MDEF': 'Magic Def.', 'MATT': 'Magic Atk.',
    # melee / ranged
    'ATT': 'Attack', 'ACC': 'Accuracy', 'EVA': 'Evasion', 'DEF': 'Defense',
    'ATTP': 'Attack%', 'RATT': 'Ranged Atk.', 'RACC': 'Ranged Acc.',
    'WSDMG': 'WS Dmg.',
    # damage-taken family (so the '_II' variants read sensibly)
    'DMGPHYS': 'PDT', 'DMGMAGIC': 'MDT', 'DMGBREATH': 'BDT', 'DMGRANGE': 'RDT',
    # jammed compounds that also appear as pieces of larger names
    'CRITHITRATE': 'Crit Hit Rate', 'FASTCAST': 'Fast Cast',
    'STORETP': 'Store TP', 'WEP': 'Weapon',
    # common words
    'RCVD': 'Received', 'ADDEFFECT': 'Added Effect', 'DWBONUS': 'Dual Wield',
    'DW': 'Dual Wield', 'PERP': 'Perpetuation', 'ELEM': 'Elemental',
    'FTP': 'fTP', 'LVL': 'Level',
}

# Tokens kept ALL-CAPS (acronyms that look wrong title-cased).
_PRETTY_UPPER = {'TP', 'HP', 'MP', 'HPP', 'MPP', 'HQ', 'NQ', 'DT', 'PDT',
                 'MDT', 'BDT', 'RDT', 'WS', 'AOE', 'JA', 'JP', 'CP', 'EXP',
                 'STR', 'DEX', 'VIT', 'AGI', 'INT', 'MND', 'CHR'}
_ROMAN_TOK = re.compile(r'^[IVX]+$')


def _pretty(enum_name: str) -> str:
    """Turn a mod.lua enum name into a readable label.
    e.g. FIRE_MACC -> 'Fire Magic Acc.',  CONVMPTOHP -> 'Convert MP->HP',
    BINDRES -> 'Bind Res.',  WALTZ_POTENCY -> 'Waltz Potency'."""
    if enum_name in _PRETTY_WHOLE:
        return _PRETTY_WHOLE[enum_name]
    # status-resistance family: <STATUS>RES -> '<Status> Res.'
    m = re.fullmatch(r'([A-Z][A-Z]+)RES', enum_name)
    if m:
        return m.group(1).title() + ' Res.'
    out = []
    for tok in enum_name.split('_'):
        if tok in _PRETTY_TOKENS:
            out.append(_PRETTY_TOKENS[tok])
        elif tok in _PRETTY_UPPER or _ROMAN_TOK.match(tok):
            out.append(tok)
        else:
            out.append(tok.title())
    return ' '.join(out)


# ---------------------------------------------------------------------------
# Stat grouping for the Gear Finder "Priority" dropdown (<optgroup> headers).
# Each used+labeled mod is bucketed into one header by its mod.lua enum-name
# keywords; generate() emits META.statGroups = ordered [groupName, [ids]] and
# the UI renders an <optgroup> per entry. Unlabeled "mod N" ids are dropped
# (not useful to prioritize on). Purely cosmetic -- never affects scores or
# which items exist.
# ---------------------------------------------------------------------------
STAT_GROUP_ORDER = [
    'Attributes', 'Melee', 'Ranged', 'Magic', 'Weapon Skill & TP',
    'Defense & Survival', 'Healing & Recovery', 'Pet',
    'Job Abilities & Traits', 'Crafting & Gathering', 'Utility & Other',
]

_ATTR_SET = {'STR', 'DEX', 'VIT', 'AGI', 'INT', 'MND', 'CHR', 'HP', 'MP',
             'HPP', 'MPP', 'CONVMPTOHP', 'CONVHPTOMP'}
_MELEE_SKILL = {'SWORD', 'AXE', 'DAGGER', 'SCYTHE', 'POLEARM', 'KATANA',
                'GAXE', 'GKATANA', 'GSWORD', 'CLUB', 'HTH', 'MARTIAL_ARTS'}
_RANGED_SKILL = {'ARCHERY', 'MARKSMAN', 'THROW'}
_DEF_SKILL = {'GUARD', 'PARRY', 'EVASION', 'SHIELD', 'DEF', 'DEFP', 'EVA'}
_MAGIC_SKILL = {'ELEMENTAL', 'DIVINE', 'ENHANCING', 'ENFEEBLING', 'DARK',
                'SUMMONING', 'NINJUTSU', 'SINGING', 'STRING', 'WIND',
                'GEOMANCY', 'BLUE', 'HANDBELL', 'STAFF'}
_CRAFT_SKILL = {'ALCHEMY', 'COOK', 'SMITH', 'GOLDSMITH', 'BONE', 'CLOTH',
                'LEATHER', 'WOOD', 'FISH', 'SYNERGY'}


def _mod_group(enum_name: str) -> str:
    """Bucket a mod (by mod.lua enum name) into one STAT_GROUP_ORDER header.
    Most-specific groups are checked first; substring rules so e.g.
    FIRE_MACC -> Magic, BINDRES -> Defense, BERSERK_DURATION -> Job."""
    e = enum_name

    def has(*ks):
        return any(k in e for k in ks)

    if e in _ATTR_SET:
        return 'Attributes'
    if has('PET', 'WYVERN', 'AVATAR', 'AUTOMATON', 'JUG', 'BLOOD_PACT'):
        return 'Pet'
    if e in _RANGED_SKILL or has('RATT', 'RACC', 'RANGED', 'SNAPSHOT',
            'RAPID_SHOT', 'BARRAGE', 'TRUE_SHOT', 'RECYCLE', 'SHARPSHOT',
            'VELOCITY', 'BOUNTY_SHOT', 'DOUBLE_SHOT'):
        return 'Ranged'
    if e.startswith('WS_') or has('SKILLCHAIN', 'WSDMG', 'WSACC', 'TP_BONUS',
            'SAVE_TP', 'CONSERVE_TP', 'FTP', 'ADDS_WEAPONSKILL', 'AFTERMATH'):
        return 'Weapon Skill & TP'
    if e == 'HEALING' or has('CURE', 'REFRESH', 'REGEN', 'HPHEAL', 'MPHEAL',
            'WALTZ', 'CURSNA', 'RERAISE'):
        return 'Healing & Recovery'
    if e in _DEF_SKILL or e == 'DMG' or e.endswith('RES') or has('DMGPHYS',
            'DMGMAGIC', 'DMGBREATH', 'DMGRANGE', 'UDMG', 'MEVA', 'MDEF',
            'COUNTER', 'PARRY', 'GUARD', 'SHIELD', 'REGAIN', 'SPIKE',
            'STONESKIN', 'PHALANX', 'ENMITY', 'ABSORB', 'EVASION', 'PROTECT',
            'SHELL', 'DAMAGE_TAKEN', 'REPRISAL', 'THIRD_EYE', 'UTSUSEMI',
            'SENTINEL', 'DEFENDER', 'KNOCKBACK', 'AQUAVEIL', 'RAMPART', 'NULL'):
        return 'Defense & Survival'
    if e in _MAGIC_SKILL or has('MAB', 'MATT', 'MACC', 'AFFINITY', 'FASTCAST',
            'NUKE', 'ENFEEBL', 'NINJUTSU', 'PERP', 'CONSERVE_MP', 'MAGIC',
            'ELEMENTAL', 'ELEM', 'SUMMONING', 'SPELLINTERRUPT', 'QUICK_MAGIC',
            'CAST', 'ENSPELL', 'STAFF_BONUS', 'GRIMOIRE', 'GEOMANCY',
            'HANDBELL', 'DARK_ARTS', 'LIGHT_ARTS'):
        return 'Magic'
    if e in _MELEE_SKILL or has('ATT', 'ACC', 'HASTE', 'DOUBLE', 'TRIPLE',
            'QUAD', 'DUAL_WIELD', 'DWBONUS', 'STORETP', 'STORE_TP', 'MARTIAL',
            'CRIT', 'SUBTLE', 'ZANSHIN', 'KICK', 'DAKEN', 'DELAY',
            'RETALIATION', 'INQUARTATA', 'SWORDPLAY', 'FENCER', 'MAIN_DMG',
            'DMG_RAT', 'MAX_SWING', 'AMMO_SWING', 'EXTRA_DMG', 'OCC_DO_EXTRA',
            'DAMAGE_LIMIT'):
        return 'Melee'
    if has('ENHANCE', 'SONG', 'BALLAD', 'MINNE', 'MARCH', 'MADRIGAL', 'MAMBO',
            'MAZURKA', 'MINUET', 'PAEON', 'PRELUDE', 'REQUIEM', 'THRENODY',
            'CAROL', 'ETUDE', 'HYMNUS', 'SCHERZO', 'FINALE', 'LULLABY',
            'VIRELAI', 'ELEGY', 'ROLL', 'PHANTOM', 'STEP', 'FLOURISH', 'JIG',
            'SAMBA', 'JUMP', 'QUICK_DRAW', 'BERSERK', 'AGGRESSOR', 'WARCRY',
            'SOULEATER', 'MEDITATE', 'HIDE', 'FLEE', 'CAMOUFLAGE', 'SNEAK',
            'BOOST', 'CHAKRA', 'FOCUS', 'DODGE', 'COUNTERSTANCE', 'KILLER',
            'CIRCLE', 'AUSPICE', 'AFFLATUS', 'BARSPELL', 'COVER', 'VALIANCE',
            'VALLATION', 'LIEMENT', 'PFLUG', 'REWARD', 'TAME', 'CHARM',
            'STEAL', 'DESPOIL', 'MUG', 'TRICK', 'SCAVENGE', 'MANEUVER',
            'INDI', 'LIFE_CYCLE', 'BLOOD_RAGE', 'RESTRAINT', 'FUTAE',
            'SENGIKORI', 'OVERLOAD', 'SUBLIMATION', 'STYMIE', 'SIPHON',
            'SABOTEUR', 'SPUR', 'SPIRIT_LINK', 'HOLYWATER', 'DIVINE_EMBLEM',
            'MANA_CEDE', 'BLITZER', 'COURSER', 'TACTICIAN', 'ALLIES', 'BASH'):
        return 'Job Abilities & Traits'
    if e in _CRAFT_SKILL or has('SYNTH', 'HARVEST', 'LOGGING', 'MINING',
            'CLAMMING', 'DIG', 'CHOCOBO', 'DESYNTH', 'GARDENING', 'REPAIR',
            'APPRECIATE', 'EAT_RAW', 'DRINK'):
        return 'Crafting & Gathering'
    return 'Utility & Other'


def _build_stat_groups(mod_labels: dict, mod_enum: dict) -> list:
    """Return [[groupName, [ids sorted by label]], ...] in STAT_GROUP_ORDER.
    Unlabeled 'mod N' ids are omitted; empty groups are dropped."""
    from collections import defaultdict
    buckets = defaultdict(list)
    for mid, lab in mod_labels.items():
        if lab.startswith('mod '):       # unknown enum -> not worth offering
            continue
        buckets[_mod_group(mod_enum.get(mid, ''))].append(mid)
    groups = []
    for name in STAT_GROUP_ORDER:
        ids = sorted(buckets.get(name, []), key=lambda i: mod_labels[i].lower())
        if ids:
            groups.append([name, ids])
    return groups


# ---------------------------------------------------------------------------
# Display-name resolution  (SQL short name -> "Proper Name +1")
# ---------------------------------------------------------------------------
_ROMAN = {'i', 'ii', 'iii', 'iv', 'v', 'vi', 'vii', 'viii', 'ix', 'x',
          'xi', 'xii', 'xiii', 'xiv', 'xv'}
# Small words that BG-Wiki / SE leave lower-case mid-name.
_LOWER = {'of', 'the', 'a', 'an', 'and', 'in', 'on', 'de', 'du', 'la'}

# Possessive first-words that SE/BG-Wiki spell with an apostrophe
# (Judges -> Judge's, Ares -> Ares'). Built by _verify_possessives.py, which
# HEAD-checks each candidate's BG-Wiki image so proper-noun weapons that merely
# end in 's' (Murgleis, Magus, Dynamis) are correctly left alone. Loaded best-
# effort; an empty map just means names keep their de-apostrophe'd SQL spelling.
try:
    _POSSESSIVE = json.loads(
        (Path(__file__).resolve().parent / "_possessive_names.json")
        .read_text(encoding="utf-8"))
except Exception:
    _POSSESSIVE = {}


def display_name(short: str) -> str:
    parts = [p for p in short.split('_') if p != '']
    out: list[str] = []
    for idx, p in enumerate(parts):
        if re.fullmatch(r'[+-]\d+', p):
            out.append(p)
        elif p in _ROMAN:
            out.append(p.upper())
        elif p in _LOWER and idx != 0:
            out.append(p)
        else:
            out.append(p[:1].upper() + p[1:])
    name = ' '.join(out)
    # Restore possessive apostrophe on the first word (verified vs BG-Wiki).
    head, sep, tail = name.partition(' ')
    if tail and head in _POSSESSIVE:
        name = _POSSESSIVE[head] + ' ' + tail
    return name


def _norm(name: str) -> str:
    """Normalize a display name back to the SQL short-name form for matching."""
    return re.sub(r'\s+', '_', name.lower().replace("'", '').replace('’', '').strip())


# ---------------------------------------------------------------------------
# SQL parsing helpers
# ---------------------------------------------------------------------------

def _read(repo_root: Path, sub: str) -> str | None:
    p = resolve_source(repo_root, sub)
    if p is None:
        return None
    return p.read_text(encoding='utf-8', errors='replace')


def _parse_mod_enum(text: str) -> dict[int, str]:
    """mod.lua: NAME = id,  -> {id: NAME} (first name wins)."""
    out: dict[int, str] = {}
    for m in re.finditer(r'^\s*([A-Z][A-Z0-9_]*)\s*=\s*(\d+)\s*,', text, re.M):
        out.setdefault(int(m.group(2)), m.group(1))
    return out


# ---------------------------------------------------------------------------
# Obtainability scan
# ---------------------------------------------------------------------------
# Pages that actually hand out items (sources), and the label to show. Guide
# pages (bis-guide, gear-guide) are deliberately excluded — they recommend
# items rather than grant them.
SOURCE_PAGES = {
    'gear-vendors.md': 'Gear Vendor',
    'dungeons.md': 'Dungeon (Infamy)',
    'augments.md': 'Augment Moogle',
    'augment-sage.md': 'Augment Sage',
    'reforge.md': 'Reforge',
    'gm-home.md': 'GM Home',
    'crafting-exchange.md': 'Crafting Exchange',
    'hunters-guild.md': "Hunter's Guild",
    'weekly-hunts.md': 'Weekly Hunt Board',
    'daily-board.md': 'Daily Board',
    'login-rewards.md': 'Login Rewards',
    'hnm.md': 'HNM',
}
# Item links now point at FFXIAH by id (ffxiah.com/item/<id>); the few
# unresolved items fall back to a BG-Wiki search url (?search=<name>). Scan BOTH
# so every linked item on a source page is detected as obtainable. (A stat-box
# item's data-img is a bg-wiki /images/ url and the icon fallback is
# /images/icon/ — neither contains /item/ or ?search=, so no false matches.)
_ITEMLINK_FFXIAH = re.compile(r'item-link[^>]*?ffxiah\.com/item/(\d+)')
_ITEMLINK_SEARCH = re.compile(r'item-link[^>]*?[?&]search=([^&"\']+)')

from urllib.parse import unquote_plus


def _scan_obtainable(docs_dir: Path, name2id: dict[str, int],
                     ambiguous_names: set[str] | None = None) -> dict[int, str]:
    """Return {itemId: source-label} for every item referenced on a source page.

    Two-phase so unambiguous ID-based item links always win over fuzzy
    name-search links. An item linked by ffxiah.com/item/<id> on ANY source
    page is tagged FIRST; name-search links then only fill gaps, and are SKIPPED
    for names shared by more than one item. The name->id map can keep just one
    id per name, so a name-search link for a duplicate name (e.g. the four "Mpu
    Gandring" stages) previously pinned the source onto one arbitrary id --
    stamping the Infamy-vendor stage with "Gear Vendor" and blocking its real
    "Dungeon (Infamy)" id-link. Within each phase, pages are still visited in
    SOURCE_PAGES order, so the first page to grant an item by id sets its label.
    """
    ambiguous_names = ambiguous_names or set()
    obtainable: dict[int, str] = {}
    prog = docs_dir / 'progression'
    pages: list[tuple[str, str]] = []
    for fname, label in SOURCE_PAGES.items():
        page = prog / fname
        if page.exists():
            pages.append((page.read_text(encoding='utf-8', errors='replace'), label))
    # Phase 1: unambiguous ID-based links (ffxiah.com/item/<id>) win.
    for text, label in pages:
        for m in _ITEMLINK_FFXIAH.finditer(text):
            obtainable.setdefault(int(m.group(1)), label)
    # Phase 2: name-search links fill gaps, skipping duplicate (ambiguous) names.
    for text, label in pages:
        for m in _ITEMLINK_SEARCH.finditer(text):
            nm = _norm(unquote_plus(m.group(1)))
            if nm in ambiguous_names:
                continue  # >1 item shares this name -> can't pick the right id
            iid = name2id.get(nm)
            if iid is not None:
                obtainable.setdefault(iid, label)
    return obtainable


# The Reforge System grants AF/Relic/Empyrean armor (base + +1/+2/+3) via NM
# drops + the Reforge Vendor. Its doc page is narrative (no per-item links), so
# tag those items straight from reforge_catalog.lua's per-job/set/slot id arrays
# (catalog.pieces[xi.job.X] = { af = { head = {base,+1,+2,+3}, ... }, ... }).
_RF_JOB_RE  = re.compile(r"catalog\.pieces\[xi\.job\.(\w+)\]\s*=\s*\{(.*?)\n\}\s*\n", re.DOTALL)
_RF_SET_RE  = re.compile(r"\b(af|relic|empy)\s*=\s*(?:--[^\n]*\n)?\s*\{(.*?)\n\s*\}", re.DOTALL)
_RF_SLOT_RE = re.compile(r"\b(head|body|hands|legs|feet)\s*=\s*\{\s*([\d,\s]+)\s*\}")


def _reforge_ids(repo_root: Path) -> set[int]:
    """Every Reforge item id (base + +1/+2/+3, all jobs/sets/slots)."""
    text = _read(repo_root, 'modules/custom/lua/reforge_catalog.lua')
    if not text:
        return set()
    ids: set[int] = set()
    for jm in _RF_JOB_RE.finditer(text):
        for sm in _RF_SET_RE.finditer(jm.group(2)):
            for slm in _RF_SLOT_RE.finditer(sm.group(2)):
                ids.update(int(x) for x in slm.group(2).split(',') if x.strip().isdigit())
    return ids


# The Prime Armory NPC (modules/custom/lua/PrimeArmory_NPC.lua) grants the 12
# apex Prime weapons for a Prime Voucher. Its doc page is narrative, and several
# Prime weapons share a name with their other upgrade stages (e.g. the four "Mpu
# Gandring" ids), so tag them straight from the NPC's WEAPONS table by id -- a
# name-search link could never pick the right stage. Row shape:
#   { id = 21589, name = 'Mpu Gandring', ws = '...', info = '...' }
_PA_ROW_RE = re.compile(r"\{\s*id\s*=\s*(\d+)\s*,\s*name\s*=")


def _prime_armory_ids(repo_root: Path) -> set[int]:
    """Every Prime weapon id granted by the Prime Armory NPC (voucher)."""
    text = _read(repo_root, 'modules/custom/lua/PrimeArmory_NPC.lua')
    if not text:
        return set()
    return {int(m.group(1)) for m in _PA_ROW_RE.finditer(text)}


# The !shop command (scripts/commands/shop.lua) sells gear from a `stock` table
# of { itemId, price } rows -- raw numeric ids AND xi.item.CONSTANT refs. There is
# no per-item doc page, so tag those ids straight from the Lua, exactly like the
# reforge / prime-armory sources above. Bounded to the `stock` table so prices and
# menu literals elsewhere can't leak in; a numeric first element is the item id
# (prices are the 2nd element and are never captured), and consumable ids that
# aren't equippable simply never match a Finder item, so they're harmless.
_SHOP_NUM_RE   = re.compile(r'\{\s*(\d+)\s*,\s*\d')
_SHOP_CONST_RE = re.compile(r'\{\s*xi\.item\.([A-Z0-9_]+)\s*,')
_ITEM_ENUM_RE  = re.compile(r'^\s*([A-Z][A-Z0-9_]*)\s*=\s*(\d+)', re.MULTILINE)


def _shop_ids(repo_root: Path) -> set[int]:
    """Every item id sold through the !shop command (scripts/commands/shop.lua)."""
    text = _read(repo_root, 'scripts/commands/shop.lua')
    if not text:
        return set()
    sm = re.search(r'\nlocal stock\b(.*?)\nlocal ', text, re.DOTALL)
    region = sm.group(1) if sm else text
    region = re.sub(r'--[^\n]*', '', region)  # drop Lua line-comments so commented-out (disabled) entries aren't flagged
    ids: set[int] = {int(m.group(1)) for m in _SHOP_NUM_RE.finditer(region)}
    consts = {m.group(1) for m in _SHOP_CONST_RE.finditer(region)}
    if consts:
        enum = {m.group(1): int(m.group(2))
                for m in _ITEM_ENUM_RE.finditer(_read(repo_root, 'scripts/enum/item.lua') or '')}
        ids.update(enum[c] for c in consts if c in enum)
    return ids


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

_DESCIMG_CACHE = None


def _descimg_for(iid: int):
    """BG-Wiki stat-box image URL for an item id, from the resolver's cache
    (tools/docgen/bgwiki_images.json). None -> the JS falls back to the icon."""
    global _DESCIMG_CACHE
    if _DESCIMG_CACHE is None:
        p = Path(__file__).resolve().parent.parent / "bgwiki_images.json"
        try:
            _DESCIMG_CACHE = ({k: v for k, v in
                               json.loads(p.read_text(encoding="utf-8")).items() if v}
                              if p.exists() else {})
        except Exception:
            _DESCIMG_CACHE = {}
    return _DESCIMG_CACHE.get(str(iid))


def generate(repo_root: Path, docs_dir: Path) -> None:
    eq_text = _read(repo_root, 'sql/item_equipment.sql')
    if not eq_text:
        print('[gear_finder] skip: sql/item_equipment.sql not found')
        return

    mod_text = _read(repo_root, 'scripts/enum/mod.lua') or ''
    mod_enum = _parse_mod_enum(mod_text)

    # --- item_basic: short name + Ex/Rare flags -----------------------------
    flags_by_id: dict[int, int] = {}
    name_by_id: dict[int, str] = {}
    basic_text = _read(repo_root, 'sql/item_basic.sql') or ''
    for ln in basic_text.splitlines():
        m = re.match(r'^INSERT INTO `item_basic` VALUES \((\d+),', ln)
        if not m:
            continue
        iid = int(m.group(1))
        fl = 0
        if re.search(r'@FLAG_EX\b', ln):
            fl |= 1
        if re.search(r'@FLAG_RARE\b', ln):
            fl |= 2
        flags_by_id[iid] = fl

    # --- item_mods: merge EVERY sql source the server loads, in load order,
    # with the right semantics. override=True -> plain INSERT / ON DUPLICATE KEY
    # UPDATE (later value wins); False -> INSERT IGNORE (fills only missing keys).
    # (Reading only item_mods.sql + zz_custom_naked under-reports reforge/relic
    # gear whose mods live in the other zz_ files.)
    mod_sources = [
        ('sql/item_mods.sql', True),
        ('sql/zz_custom_naked_item_mods.sql', True),
        ('sql/zz_derived_tier_mods.sql', False),
        ('sql/zz_infamy_extra_mods.sql', True),
        ('sql/zz_naked_dungeon_fix.sql', False),
        ('sql/zz_obtainable_gap_fills.sql', False),
        ('sql/zz_reforge_plus12_displayed_stats.sql', False),
        ('sql/zz_reforge_plus3_displayed_stats.sql', False),
        ('sql/zz_reforge_plus3_outliers.sql', False),
        ('sql/zz_reforge_plus4_displayed_stats.sql', False),
        ('sql/zz_relic_119iii_mods.sql', False),
        ('sql/zz_tokko_voluspa_mods.sql', False),
        ('sql/zzz_reforge_carryforward.sql', False),   # tier carry-forward (loads last)
    ]
    _tuple_re = re.compile(r'\((\d+),(\d+),(-?\d+)\)')
    mods: dict[int, dict[int, int]] = defaultdict(dict)
    for fn, override in mod_sources:
        t = _read(repo_root, fn)
        if not t:
            continue
        for ln in t.splitlines():
            if 'item_mods`' not in ln:
                continue
            for m in _tuple_re.finditer(ln):
                iid, mid, val = int(m.group(1)), int(m.group(2)), int(m.group(3))
                d = mods[iid]
                if override or mid not in d:
                    d[mid] = val

    # --- item_latents -------------------------------------------------------
    latents: dict[int, list[tuple[int, int, int]]] = defaultdict(list)
    lt_text = _read(repo_root, 'sql/item_latents.sql') or ''
    for ln in lt_text.splitlines():
        m = re.match(r'^INSERT INTO `item_latents` VALUES \((\d+),(\d+),(-?\d+),(-?\d+),(-?\d+)\)', ln)
        if m:
            latents[int(m.group(1))].append((int(m.group(2)), int(m.group(3)), int(m.group(4))))

    # Normalize x10/x100/x10000 mods to their human/BG-Wiki value (see MOD_SCALE),
    # so displayed values match the game (700 -> 7). Keep ints when whole.
    def _norm_val(v, div):
        q = v / div
        return int(q) if q == int(q) else round(q, 2)
    for _mm in mods.values():
        for _m, _div in MOD_SCALE.items():
            if _m in _mm:
                _mm[_m] = _norm_val(_mm[_m], _div)
    for _lst in latents.values():
        for _j in range(len(_lst)):
            _mid, _v, _lid = _lst[_j]
            if _mid in MOD_SCALE:
                _lst[_j] = (_mid, _norm_val(_v, MOD_SCALE[_mid]), _lid)

    # --- item_weapon: skill / delay / dmg -----------------------------------
    weapons: dict[int, tuple[int, int, int]] = {}
    wp_text = _read(repo_root, 'sql/item_weapon.sql') or ''
    for ln in wp_text.splitlines():
        m = re.match(
            r"^INSERT INTO `item_weapon` VALUES \((\d+),'[^']*',(\d+),(-?\d+),"
            r"(-?\d+),(-?\d+),(-?\d+),(\d+),(\d+),(-?\d+),(\d+),", ln)
        if m:
            iid, skill, delay, dmg = (int(m.group(1)), int(m.group(2)),
                                      int(m.group(9)), int(m.group(10)))
            weapons[iid] = (skill, dmg, delay)

    # --- role scoring (mirrors build_items_spreadsheet.py) ------------------
    def role_score(iid: int, role: str) -> float:
        w = ROLE_WEIGHTS[role]
        s = 0.0
        for mid, val in mods.get(iid, {}).items():
            ww = w.get(mid)
            if ww:
                s += _clamp(mid, val) * ww
        for mid, val, latent_id in latents.get(iid, []):
            ww = w.get(mid)
            if not ww:
                continue
            full = role in ('DPS', 'WS') and latent_id in DD_ALWAYS_LATENTS
            s += _clamp(mid, val) * ww * (1.0 if full else 0.5)
        return s

    def weapon_bonus(iid: int, slotmask: int, role: str) -> float:
        """Weapon output term for a real Main/Sub/Range weapon: sustained DPS
        for the DPS role, raw base damage for WS (heavy/slow weapons favour WS)."""
        wp = weapons.get(iid)
        if not wp:
            return 0.0
        skill, dmg, delay = wp
        if delay >= 50 and skill in COMBAT_SKILLS and (slotmask & 0b111):
            if role == 'DPS':
                return (dmg * 60 / delay) * 2.0
            if role == 'WS':
                return dmg * 0.5
        return 0.0

    # --- assemble items -----------------------------------------------------
    items = []
    used_mods: set[int] = set()
    eq_re = re.compile(
        r"^INSERT INTO `item_equipment` VALUES \((\d+),'([^']*)',(\d+),(\d+),"
        r"(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+)\)")
    for ln in eq_text.splitlines():
        m = eq_re.match(ln)
        if not m:
            continue
        iid = int(m.group(1))
        short = m.group(2)
        if iid in EXCLUDED_ITEM_IDS or short.startswith(EXCLUDED_NAME_PREFIXES):
            continue  # NPC-only / non-player junk — keep it out of the Finder
        level = int(m.group(3))
        ilevel = int(m.group(4))
        jobmask = int(m.group(5))
        slotmask = int(m.group(9))
        su = int(m.group(12))
        name_by_id[iid] = short

        obj: dict = {'i': iid, 'n': display_name(short), 's': slotmask, 'j': jobmask}
        if level:
            obj['l'] = level
        if ilevel:
            obj['il'] = ilevel
        if su:
            obj['su'] = su
        fl = flags_by_id.get(iid, 0)
        if fl:
            obj['f'] = fl

        di = _descimg_for(iid)
        if di:
            obj['img'] = di  # BG-Wiki stat-box image for the hover pop-up

        wp = weapons.get(iid)
        if wp:
            obj['w'] = list(wp)  # [skill, dmg, delay]

        im = mods.get(iid)
        if im:
            pairs = [[k, v] for k, v in sorted(im.items()) if v != 0]
            if pairs:
                obj['m'] = pairs
                used_mods.update(k for k, _ in pairs)
        lt = latents.get(iid)
        if lt:
            obj['lt'] = [[mid, val, lid] for (mid, val, lid) in lt]
            used_mods.update(mid for mid, _, _ in lt)

        # Role scores — only for jobs that can wear it; keep >0 only.
        # Weapon term: DPS gets sustained (dmg/delay), WS gets base damage.
        scores = []
        any_score = False
        for role in ('DPS', 'TANK', 'CASTER', 'HEAL', 'WS', 'PET'):
            if jobmask and (jobmask & ROLE_MASKS[role]) == 0:
                scores.append(0)
                continue
            v = round(role_score(iid, role) + weapon_bonus(iid, slotmask, role))
            scores.append(v if v > 0 else 0)
            if v > 0:
                any_score = True
        if any_score:
            obj['sc'] = scores

        items.append(obj)

    # --- obtainability (after the source pages exist) -----------------------
    # A name shared by >1 item id can't be resolved from a name-search link, so
    # the scan must skip those (otherwise one arbitrary id steals the source --
    # the "Mpu Gandring" 4-stage bug). Build the duplicate-name set up front.
    from collections import Counter
    _name_counts = Counter(_norm(display_name(s)) for s in name_by_id.values())
    ambiguous_names = {nm for nm, c in _name_counts.items() if c > 1}
    name2id = {_norm(display_name(s)): i for i, s in name_by_id.items()}
    obtainable = _scan_obtainable(docs_dir, name2id, ambiguous_names)
    # Reforge items (narrative page, no links) — fill in any not already tagged
    # by a vendor/dungeon page (those direct-purchase sources take precedence).
    for iid in _reforge_ids(repo_root):
        obtainable.setdefault(iid, 'Reforge')
    # Prime Armory NPC (voucher-granted, narrative page) — tag the apex Prime
    # weapons by catalog id so they aren't shown as unobtainable. Gap-fill: a
    # Prime weapon also sold by a vendor keeps its more specific vendor tag.
    for iid in _prime_armory_ids(repo_root):
        obtainable.setdefault(iid, 'Prime Armory')
    # !shop command (scripts/commands/shop.lua): direct-purchase gear, no per-item
    # doc page. Runs last so an item also sold by a medal vendor keeps its tag.
    for iid in _shop_ids(repo_root):
        obtainable.setdefault(iid, '!shop')
    for obj in items:
        src = obtainable.get(obj['i'])
        if src:
            obj['o'] = src
            obj['f'] = obj.get('f', 0) | 4  # bit2 = obtainable

    # --- mod labels (only the ones actually used) ---------------------------
    mod_labels = {}
    for mid in sorted(used_mods):
        if mid in MOD_LABELS:
            mod_labels[mid] = MOD_LABELS[mid]
        elif mid in mod_enum:
            mod_labels[mid] = _pretty(mod_enum[mid])
        else:
            mod_labels[mid] = f'mod {mid}'

    # Group the labeled mods into <optgroup> headers for the Priority dropdown.
    stat_groups = _build_stat_groups(mod_labels, mod_enum)

    payload = {
        'generated_at': time.strftime('%Y-%m-%dT%H:%M:%S'),
        'meta': {
            'jobs': JOBS,
            'slotOrder': SLOT_ORDER,
            'slotBits': SLOT_BITS,
            'weaponSkills': {str(k): v for k, v in WEAPON_SKILLS.items()},
            'modLabels': {str(k): v for k, v in mod_labels.items()},
            'statGroups': stat_groups,
            'roles': ['DPS', 'TANK', 'CASTER', 'HEAL', 'WS', 'PET'],
        },
        'items': items,
    }

    out = docs_dir / 'assets' / 'gear-data.json'
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(payload, separators=(',', ':')), encoding='utf-8')
    n_obt = sum(1 for it in items if 'o' in it)
    size_kb = out.stat().st_size // 1024
    print(f'[gear_finder] wrote {out.name}: {len(items)} items '
          f'({n_obt} obtainable, {len(mod_labels)} mods, {size_kb} KB)')
