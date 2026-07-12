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

import hashlib
import json
import re
import time
from collections import defaultdict
from pathlib import Path

from tools.docgen._markers import write_between_markers
from tools.docgen._paths import resolve_source
from tools.docgen._item_sources import collect_drop_sources

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

# Combat weapon skills (melee 1-12 + ranged 25/26/27) used to gate the Main/Sub/
# Range DPS+WS output term in weapon_bonus(). Instruments (40-45) are excluded --
# they're weapons but not damage sources. Restored after a9e43e567a's role-weight
# dedupe accidentally dropped this constant (broke the whole generator -> stale
# gear-data.json since 2026-07-05).
COMBAT_SKILLS = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 25, 26, 27}

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
# ---------------------------------------------------------------------------
# Role weights, sanity caps and the DD-latent set live in ONE shared module
# (tools/scoring_weights.py) so the four scorers can never drift. EDIT WEIGHTS
# THERE, not here. (Previously each scorer kept its own hand-synced copy.)
# ---------------------------------------------------------------------------
try:
    from tools.scoring_weights import ROLE_WEIGHTS, MOD_SANITY_CAP, CAP_DEFAULT, DD_ALWAYS_LATENTS
except ImportError:  # run as `python tools/score_*.py` (tools/ is sys.path[0])
    from scoring_weights import ROLE_WEIGHTS, MOD_SANITY_CAP, CAP_DEFAULT, DD_ALWAYS_LATENTS

# Weapon-skill ids that count as real melee/ranged COMBAT weapons: weapon_bonus
# only credits dmg/delay DPS for these (1-12 melee, 25/26/27 ranged) -- excludes
# instruments/handbells so a harp never scores as a DPS weapon.
# NOTE: this constant was accidentally swept out when the scoring constants moved
# into scoring_weights.py (a9e43e567a, 2026-07-05) -- it sat next to MOD_SANITY_CAP.
# Leaving it undefined made weapon_bonus raise NameError as soon as any item_weapon
# row loaded, CRASHING gear_finder every docs build and freezing gear-data.json
# (the Gear Finder stopped updating on 2026-07-05). Restored here, verbatim.
COMBAT_SKILLS = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 25, 26, 27}

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
    # Keys are relative to docs/progression/ unless they contain a '/', in
    # which case they resolve from docs_dir (e.g. the endgame pages).
    'endgame/domain-invasion.md': 'Domain QM',
    'economy/cosmetic-boutique.md': 'Cosmetic Boutique',
    # dungeons.md lives in endgame/ -- the old progression-relative key
    # resolved to a non-existent path and the scan SILENTLY skipped all 146
    # of its item links (found 2026-07-12 via "Agony Jerkin +1 is Unity").
    'endgame/dungeons.md': 'Dungeon (Infamy)',
    'augments.md': 'Augment Moogle',
    'augment-sage.md': 'Augment Sage',
    'reforge.md': 'Reforge',
    'gm-home.md': 'GM Home',
    'hunters-guild.md': "Hunter's Guild",
    'weekly-hunts.md': 'Weekly Hunt Board',
    'daily-board.md': 'Daily Board',
    'login-rewards.md': 'Login Rewards',
    'hnm.md': 'HNM',
    # Source pages that were never registered (same audit): every page below
    # item-links gear a player earns through that system.
    'endgame/unity-concord.md': 'Unity Wanted NM',
    'endgame/high-tier-battlefields.md': 'HTBF',
    'endgame/nyzul-isle.md': 'Nyzul Isle',
    'endgame/voidwatch.md': 'Voidwatch',
    'endgame/dynamis-classic.md': 'Classic Dynamis',
    'endgame/ambuscade.md': 'Ambuscade',
    'aeonic-weapons.md': 'Aeonic Forge (Temprix)',
    # Geas Fete roster tables item-link every NM's retail signature drops.
    'endgame/geas-fete.md': 'Geas Fete',
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
        page = (docs_dir / fname) if '/' in fname else (prog / fname)
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


def _plus4_forge_ids(repo_root: Path) -> set[int]:
    """The +4 results of the Divergence Forge (reforge_plus4_map.lua result
    ids). Without this tag the 220 +4 items are absent from gear-data.json
    entirely — the audit that flagged 'Foire Tobe +4 not available' was
    reading that absence (found 2026-07-12)."""
    text = _read(repo_root, 'modules/custom/lua/reforge_plus4_map.lua')
    if not text:
        return set()
    return {int(x) for x in re.findall(r'\bresult\s*=\s*(\d+)', text)}


def _unity_plus1_ids(repo_root: Path) -> set[int]:
    """The +1 versions of Unity Wanted drops — obtained by trading the base
    item + Unity Accolades to the Wanted Board (2026-07-12 upgrade path).
    The base items get tagged from the page's item links; the +1s appear on
    no page table, so tag them straight from the catalog's plus1 fields."""
    text = _read(repo_root, 'modules/custom/lua/unity_wanted_catalog.lua')
    if not text:
        return set()
    return {int(x) for x in re.findall(r'\bplus1\s*=\s*(\d+)', text)}


def _dynamis_su5_ids(repo_root: Path) -> set[int]:
    """The Su5 (Dynamis Divergence) weapons that drop from the [D] Mega-Bosses
    via the SU5_WEAPONS pool in scripts/globals/dynamis_divergence.lua (moved
    there from the removed any-Abyssea-mob roll, 2026-07-12)."""
    text = _read(repo_root, 'scripts/globals/dynamis_divergence.lua')
    if not text:
        return set()
    m = re.search(r'SU5_WEAPONS\s*=\s*\n\{(.*?)\n\}', text, re.DOTALL)
    if not m:
        return set()
    return {int(x) for x in re.findall(r'\{\s*id\s*=\s*(\d+)', m.group(1))}


def _geas_fete_gear_ids(repo_root: Path) -> set[int]:
    """The Reisenjima-crafted armor (Adhemar/Argosy/Carmine/Rao/Ryuo/Souveran/
    Naga, NQ + +1) that drops off Geas-Fete T2+ NMs -- the GEAR_NQ/GEAR_HQ
    pools in modules/custom/lua/Geas_Fete.lua (their only source since the
    2026-07 vendor sweep)."""
    text = _read(repo_root, 'modules/custom/lua/Geas_Fete.lua')
    if not text:
        return set()
    ids: set[int] = set()
    for mm in re.finditer(r'local GEAR_(?:NQ|HQ)\s*=\s*\{(.*?)\n\}', text, re.DOTALL):
        ids |= {int(x) for x in re.findall(r'\b(2\d{4})\b', mm.group(1))}
    return ids


def _catalog_ids(repo_root: Path, relpath: str) -> set[int]:
    """All `id = N` stock rows in a vendor/forge catalog lua. The docs pages
    render CURATED SUBSETS of these catalogs, so page-scanning alone
    under-reports -- the catalog is the source of truth (the 'Agony Jerkin'
    audit, 2026-07-12, found 112 grantable-but-unmapped items this way)."""
    text = _read(repo_root, relpath)
    if not text:
        return set()
    return {int(x) for x in re.findall(r'\bid\s*=\s*(\d{4,5})\b', text)}


# Catalog-backed sources scanned by id, label -> catalog files. Applied after
# the page scan (page labels are equivalent anyway) and before the fallbacks.
CATALOG_SOURCES = [
    ('Gear Vendor', ['modules/custom/lua/armor_catalog.lua',
                     'modules/custom/lua/accessory_catalog.lua',
                     'modules/custom/lua/gear_progression_catalog.lua']),
    ('Infamy Vendor', ['modules/custom/lua/infamy_vendor_catalog.lua']),
    ('Weapon Forge', ['modules/custom/lua/weapon_forge_catalog.lua',
                      'modules/custom/lua/Relic_Forge.lua']),
    ('Affinity NMs', ['modules/custom/lua/augment_affinity_catalog.lua']),
]


def _ambuscade_ids(repo_root: Path) -> set[int]:
    """Every item the Ambuscade system hands out: the 10 armor sets
    (NQ/+1/+2 from ARMOR_SETS in scripts/globals/ambuscade.lua -- NQ/+1 via
    Voucher Clerk, upgrades via Abdhaljs trades at Gorpa-Masorpa) plus the
    weapon chains (all 5 stages per type from ambuscade_weapons_catalog.lua).
    Vendor-page tags win via setdefault order; the Tokko/Ajja stages shared
    with the Prime WeaponForge keep their 'Prime Armory' tag (deliberate)."""
    ids: set[int] = set()
    text = _read(repo_root, 'scripts/globals/ambuscade.lua')
    if text:
        m = re.search(r'local ARMOR_SETS\s*=(.*?)local JOB_SETS', text, re.DOTALL)
        if m:
            ids |= {int(x) for x in re.findall(r'\b(2\d{4})\b', m.group(1))}
        # HM shop rows in the equipment id range (the set rings; the Abdhaljs
        # materials/vouchers are 9xxx and stay out).
        m = re.search(r'local HM_SHOP\s*=\s*\{(.*?)\n\}', text, re.DOTALL)
        if m:
            ids |= {int(x) for x in re.findall(r'\{\s*(2\d{4}),', m.group(1))}
    text = _read(repo_root, 'modules/custom/lua/ambuscade_weapons_catalog.lua')
    if text:
        for mm in re.finditer(r'stages\s*=\s*\{([^}]*)\}', text):
            ids |= {int(x) for x in re.findall(r'\b(\d{5})\b', mm.group(1))}
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
        ('sql/zz_zurim_gear_mods.sql', False),
        # reward-item stats authored for the 2026-07 Skirmish/Geas-Fete drops
        ('modules/custom/sql/skirmish_fete_gear_stats.sql', True),
        ('sql/zzz_reforge_carryforward.sql', False),   # tier carry-forward (loads last)
    ]
    # Tolerate spaces after commas, e.g. "(23756, 1, 152)" (Gleti set) -- the
    # old no-space pattern silently skipped those rows (mirrors _item_mods.py).
    _tuple_re = re.compile(r'\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(-?\d+)\s*\)')
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
    # The Domain QM / Zurim ammo dispensers are linked by their POUCH id on the
    # source page; tag the ammo each pouch dispenses (scripts/items/*.lua):
    # Voluspa Quiver->Arrow, Bolt Quiver->Bolt, Bullet Pouch->Bullet,
    # Date Shuriken Pouch->Date Shuriken.
    for iid in (22289, 22290, 22291, 22292):
        obtainable.setdefault(iid, 'Domain QM')
    # Reforge items (narrative page, no links) — fill in any not already tagged
    # by a vendor/dungeon page (those direct-purchase sources take precedence).
    for iid in _reforge_ids(repo_root):
        obtainable.setdefault(iid, 'Reforge')
    # Prime Armory NPC (voucher-granted, narrative page) — tag the apex Prime
    # weapons by catalog id so they aren't shown as unobtainable. Gap-fill: a
    # Prime weapon also sold by a vendor keeps its more specific vendor tag.
    for iid in _prime_armory_ids(repo_root):
        obtainable.setdefault(iid, 'Prime Armory')
    # Catalog-backed vendors/forges by id: the pages render curated subsets,
    # so the catalogs themselves are scanned too (full stock counts).
    for label, files in CATALOG_SOURCES:
        for relpath in files:
            for iid in _catalog_ids(repo_root, relpath):
                obtainable.setdefault(iid, label)
    # Ambuscade: the 10 armor sets (NQ/+1/+2) + weapon chains are earned inside
    # Ambuscade (vouchers, Hallmarks, Abdhaljs upgrades). Exclusive since the
    # 2026-07 vendor sweep -- this tag is their only source.
    for iid in _ambuscade_ids(repo_root):
        obtainable.setdefault(iid, 'Ambuscade')
    # Geas-Fete: the Reisenjima-crafted armor families drop off T2+ fete NMs
    # (GEAR_NQ/GEAR_HQ in Geas_Fete.lua) -- exclusive since the 2026-07 sweep.
    for iid in _geas_fete_gear_ids(repo_root):
        obtainable.setdefault(iid, 'Geas Fete')
    # !shop command (scripts/commands/shop.lua): direct-purchase gear, no per-item
    # doc page. Runs last so an item also sold by a medal vendor keeps its tag.
    for iid in _shop_ids(repo_root):
        obtainable.setdefault(iid, '!shop')
    # Su5 (Dynamis Divergence) weapons drop from the [D] Mega-Bosses (pool in
    # scripts/globals/dynamis_divergence.lua). Gap-fill: a Su5 weapon also
    # sold somewhere keeps its more specific tag.
    for iid in _dynamis_su5_ids(repo_root):
        obtainable.setdefault(iid, 'Dynamis [D] Mega-Boss')
    # +4 reforge results forged at the Divergence Forge (reforge_plus4_map.lua)
    # — trade a +3 piece + [D] materials. Without this the +4 tier is invisible
    # to the Gear Finder / item database.
    for iid in _plus4_forge_ids(repo_root):
        obtainable.setdefault(iid, 'Divergence +4 Forge')
    # Unity Wanted +1s: upgraded from the base drop at the Wanted Board for
    # accolades. The base items come from the page scan; these have no table.
    for iid in _unity_plus1_ids(repo_root):
        obtainable.setdefault(iid, 'Unity upgrade')
    # Full source list per item: merge the coarse system label (vendor /
    # reforge / !shop / dungeon / augment-moogle, from obtainable[iid]) with the
    # COMPLETE drop-source list (live mob_droplist + every scripted drop table)
    # shared with the Item Database via collect_drop_sources -- so each item
    # shows ALL of its real sources, not just one, and the two pages never
    # disagree. obj['src'] is a list of {'s': "System label"} and/or drop rows
    # {'m': mob, 'z': zone, 'p': pct}. The compact obj['o'] (Source column) is
    # the system tag when there is one, else the top drop's mob; bit2 of obj['f']
    # (= obtainable) is set whenever EITHER kind of source exists (so drop-only
    # gear is no longer wrongly shown/filtered as unobtainable).
    SRC_CAP = 15  # cap drop rows per item so gear-data.json stays compact
    drop_sources, _db_ok = collect_drop_sources(repo_root)

    # ---- GRANT GUARD -------------------------------------------------------
    # Sweep every code path that can hand a player an item (custom droplist
    # SQL, catalog luas, addItem/giveItem literals) and warn about equippable
    # ids the source map above does NOT know. Every warning here is a
    # player-visible lie in the Gear Finder ("obtainable gear shown as
    # unobtainable") -- fix by adding a SOURCE_PAGES entry, a CATALOG_SOURCES
    # row, or a dedicated *_ids gap-fill. Added after the 'Agony Jerkin +1 is
    # Unity' report (2026-07-12) so these gaps surface at build time, not via
    # player reports.
    all_ids = {obj['i'] for obj in items}
    grantable: dict = {}
    sql_dir = repo_root / 'modules' / 'custom' / 'sql'
    if sql_dir.exists():
        for p in sql_dir.glob('*.sql'):
            t = p.read_text(encoding='utf-8', errors='replace')
            for m in re.finditer(
                    r'INSERT INTO\s+`?mob_droplist`?\s+VALUES\s*\(\s*\d+\s*,'
                    r'\s*\d+\s*,\s*\d+\s*,\s*\d+\s*,\s*(\d+)', t):
                grantable.setdefault(int(m.group(1)), p.name)
    _grant_pat = re.compile(
        r'(?:addItem|giveItem)\s*\(\s*(?:player\s*,\s*)?\{?\s*(?:id\s*=\s*)?(\d{4,5})\b')
    _row_pat = re.compile(r'\bid\s*=\s*(\d{4,5})\b')
    for base in ('modules/custom', 'scripts/commands', 'scripts/globals'):
        broot = repo_root / base
        if not broot.exists():
            continue
        for p in broot.rglob('*.lua'):
            t = p.read_text(encoding='utf-8', errors='replace')
            for m in _grant_pat.finditer(t):
                grantable.setdefault(int(m.group(1)), p.name)
            if 'catalog' in p.name.lower():
                for m in _row_pat.finditer(t):
                    grantable.setdefault(int(m.group(1)), p.name)
    unmapped = sorted(
        (iid, fn) for iid, fn in grantable.items()
        if iid in all_ids and iid not in obtainable
        and iid not in drop_sources)
    if unmapped:
        print(f'[gear_finder] !! GRANT GUARD: {len(unmapped)} grantable '
              f'equippable item(s) missing from the source map:')
        for iid, fn in unmapped[:20]:
            print(f'[gear_finder] !!   {iid}  (granted by {fn})')
        if len(unmapped) > 20:
            print(f'[gear_finder] !!   ... +{len(unmapped) - 20} more')
    for obj in items:
        iid = obj['i']
        sys_label = obtainable.get(iid)
        rows = sorted(drop_sources.get(iid, []),
                      key=lambda d: -(d.get('pct') or 0))
        src: list = []
        if sys_label:
            src.append({'s': sys_label})
        for d in rows[:SRC_CAP]:
            e = {'m': d['mob']}
            if d.get('zone'):
                e['z'] = d['zone']
            if d.get('pct') is not None:
                e['p'] = d['pct']
            src.append(e)
        if not src:
            continue  # no vendor tag and no drop -> genuinely unobtainable
        obj['src'] = src
        obj['o'] = sys_label or ('Drop: ' + rows[0]['mob'])
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
    n_src = sum(1 for it in items if 'src' in it)
    n_drop = sum(1 for it in items if any('m' in s for s in it.get('src', [])))
    size_kb = out.stat().st_size // 1024
    print(f'[gear_finder] wrote {out.name}: {len(items)} items '
          f'({n_obt} obtainable, {n_src} with sources, {n_drop} with drops, '
          f'{len(mod_labels)} mods, {size_kb} KB)')

    # gear-finder.md is a static shell -- the content players see lives in
    # gear-data.json, loaded by JS -- so the page's content-aware "Last
    # updated" footer never moved when the dataset did, and the page-index
    # staleness report called the tool stale. Mirror the dataset's fingerprint
    # into a marker block: a real data change alters the block and advances
    # the stamp. generated_at is excluded so a no-op regen keeps the date.
    rev = hashlib.sha256(json.dumps(
        {'meta': payload['meta'], 'items': items},
        separators=(',', ':')).encode('utf-8')).hexdigest()[:12]
    write_between_markers(
        docs_dir / 'progression' / 'gear-finder.md', 'gear-finder-dataset',
        f'**{len(items):,}** equippable items indexed ({n_obt:,} obtainable '
        f'on the Relaunch server, {n_src:,} with acquisition sources) — the '
        f'dataset regenerates from live server data on every deploy.\n'
        f'<!-- dataset-rev: {rev} -->')
