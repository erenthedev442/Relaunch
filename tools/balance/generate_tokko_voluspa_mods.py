"""Generate SQL to populate item_mods for the empty Tokko / Voluspa weapons.

Context: the gold-vendor catalog (gear_progression_catalog.lua) sells a
Tokko series (15 gold marks) and a Voluspa series (12 gold marks) as
lower-tier alternatives to the 50-mark REMA III / 60-mark Aeonic top-end
weapons. Upstream LSB shipped these items with base DMG/Delay set in
item_weapon but EMPTY item_mods — players spend gold marks, get a weapon
with no stat bonuses.

Strategy: apply a per-skill-type stat template calibrated to the cluster
of healthy mid-tier weapons we observed in the DB (Arasy line, Air Knife,
Fettering Blade, etc.). Tokko items get the baseline; Voluspa items get
the baseline minus a small step (Tokko 15-mark > Voluspa 12-mark cost-wise,
so Tokko should be slightly stronger).

The templates lean into weapon-type identity:
  - Daggers / Katanas: DEX-flavored, fast-attack profile
  - Swords / Great Swords / Polearms: STR-flavored, melee DD
  - Staves / Clubs: caster-flavored (MATT, MACC, INT/MND)
  - Archery / Marksmanship: RATT / RACC / AGI

INSERT IGNORE preserves any existing item_mods rows (in case some Tokko/
Voluspa items aren't actually empty, or have a token effect mod we don't
want to clobber). Idempotent.

Usage:
    python tools/balance/generate_tokko_voluspa_mods.py
Output:
    sql/zz_tokko_voluspa_mods.sql

The output lives in /sql/ with a `zz_` prefix so it loads alphabetically
AFTER /sql/item_mods.sql (which does DROP TABLE on every full update).
Without the prefix, every `dbtool update full` would silently wipe these
rows.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT))

from tools.docgen._db import connect  # noqa: E402
from tools.docgen._paths import resolve_source  # noqa: E402


# Templates keyed by mod NAME — resolved to numeric IDs at runtime from
# scripts/enum/mod.lua. Avoids the "I memorized the wrong ID" bug class
# (e.g. ACC is 25 not 24; my first attempt at this file had RACC=29 which
# is actually MDEF in the DB — random stats would have shipped).
#
# Skill IDs from scripts/enum/skill.lua:
#   1 H2H | 2 Dagger | 3 Sword | 4 GreatSword | 5 Axe | 6 GreatAxe |
#   7 Scythe | 8 Polearm | 9 Katana | 10 GreatKatana | 11 Club |
#   12 Staff | 25 Archery | 26 Marksmanship
#
# Stat magnitudes calibrated to sit BETWEEN the Arasy line (stats +6-12,
# ATT+15) and Air Knife / Fettering Blade (stats +20-30, ATT+25). Viable
# but distinctly below REMA III (which has 8+ specialty mods, not just
# raw stat bonuses).
VOLUSPA_TEMPLATE_BY_NAME: dict[int, dict[str, int]] = {
    1:  { 'STR': 12, 'DEX': 8,  'ATT': 22, 'ACC': 22, 'HP': 50, 'HASTE_GEAR': 200, 'CRITHITRATE': 2 },      # H2H
    2:  { 'DEX': 12, 'AGI': 8,  'ATT': 18, 'ACC': 28, 'EVA': 18, 'HASTE_GEAR': 300, 'CRITHITRATE': 3 },     # Dagger
    3:  { 'STR': 12, 'DEX': 6,  'ATT': 22, 'ACC': 22, 'HP': 50, 'CRITHITRATE': 3 },                          # Sword
    4:  { 'STR': 14, 'VIT': 8,  'ATT': 28, 'ACC': 18, 'HP': 70 },                                            # Great Sword
    5:  { 'STR': 12, 'DEX': 6,  'ATT': 25, 'ACC': 18, 'HP': 60 },                                            # Axe
    6:  { 'STR': 14, 'VIT': 10, 'ATT': 30, 'ACC': 15, 'HP': 80 },                                            # Great Axe
    7:  { 'STR': 12, 'INT': 8,  'MND': 8,  'ATT': 22, 'HP': 60 },                                            # Scythe
    8:  { 'STR': 12, 'DEX': 8,  'ATT': 28, 'ACC': 18, 'HP': 70 },                                            # Polearm
    9:  { 'DEX': 12, 'STR': 6,  'ATT': 20, 'ACC': 25, 'HASTE_GEAR': 200, 'CRITHITRATE': 3 },                 # Katana
    10: { 'STR': 12, 'DEX': 8,  'ATT': 25, 'ACC': 22, 'HP': 60 },                                            # Great Katana
    11: { 'MND': 12, 'INT': 6,  'MATT': 12, 'MACC': 10, 'MP': 50, 'MAGIC_DAMAGE': 80 },                      # Club
    12: { 'INT': 12, 'MND': 10, 'MATT': 14, 'MACC': 10, 'MP': 70, 'MAGIC_DAMAGE': 100 },                     # Staff
    25: { 'AGI': 12, 'DEX': 8,  'RATT': 22, 'RACC': 22 },                                                    # Archery
    26: { 'AGI': 12, 'DEX': 8,  'RATT': 22, 'RACC': 22 },                                                    # Marksmanship
}


# Tokko (15 marks) gets a small additive bonus on top of Voluspa (12 marks).
TOKKO_BUMP_BY_NAME: dict[str, int] = {
    'STR': 2, 'DEX': 2, 'VIT': 2, 'AGI': 2, 'INT': 2, 'MND': 2, 'CHR': 2,
    'ATT': 5, 'ACC': 5, 'RATT': 5, 'RACC': 5,
    'MATT': 2, 'MACC': 2,
    'HP': 15, 'MP': 15,
    'HASTE_GEAR': 50,
    'CRITHITRATE': 1,
    'MAGIC_DAMAGE': 20,
    'EVA': 4,
}


def _resolve_templates(name_to_id: dict[str, int]) -> tuple[dict[int, dict[int, int]], dict[int, int]]:
    """Convert NAME-keyed templates to ID-keyed by resolving via mod.lua.
    Loudly warns on any unknown name — that's how we catch typos."""
    out_templates: dict[int, dict[int, int]] = {}
    out_bump: dict[int, int] = {}
    missing: set[str] = set()
    for skill, template in VOLUSPA_TEMPLATE_BY_NAME.items():
        resolved = {}
        for name, value in template.items():
            mod_id = name_to_id.get(name)
            if mod_id is None:
                missing.add(name)
                continue
            resolved[mod_id] = value
        out_templates[skill] = resolved
    for name, value in TOKKO_BUMP_BY_NAME.items():
        mod_id = name_to_id.get(name)
        if mod_id is None:
            missing.add(name)
            continue
        out_bump[mod_id] = value
    if missing:
        raise SystemExit(f'ERROR: unknown mod names in templates: {sorted(missing)} '
                         f'— check scripts/enum/mod.lua for the correct name')
    return out_templates, out_bump


def main() -> int:
    conn = connect(REPO_ROOT)
    if conn is None:
        print('DB connection failed.')
        return 1
    cur = conn.cursor()

    # Identify every Tokko / Voluspa weapon. Exclude pure ammo/grip/shield
    # items — those have skill=0 or weird weapon-type IDs.
    cur.execute(
        """
        SELECT b.itemId, b.name, w.skill
        FROM item_basic b
        JOIN item_weapon w ON w.itemId = b.itemId
        WHERE (b.name LIKE 'tokko_%' OR b.name LIKE 'voluspa_%' OR b.name = 'tokkosho')
          AND w.skill IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 25, 26)
        ORDER BY b.name
        """
    )
    items = cur.fetchall()
    if not items:
        print('No Tokko / Voluspa weapons found.')
        return 0
    print(f'Found {len(items)} Tokko/Voluspa weapons to populate.')

    # Mod-name lookup (for SQL comments + template name resolution).
    mod_lua_path = resolve_source(REPO_ROOT, 'scripts/enum/mod.lua')
    if mod_lua_path is None:
        print('mod.lua not found')
        return 1
    mods_txt = mod_lua_path.read_text(encoding='utf-8', errors='replace')
    name_by_id = {int(m.group(2)): m.group(1)
                  for m in re.finditer(r'^\s+([A-Z][A-Z0-9_]+)\s*=\s*(\d+)', mods_txt, re.M)}
    name_to_id = {nm: mid for mid, nm in name_by_id.items()}

    # Resolve name-keyed templates to ID-keyed templates. Raises loudly on
    # any unknown mod name so we don't ship random stats.
    voluspa_template, tokko_bump = _resolve_templates(name_to_id)
    print(f'  resolved {sum(len(t) for t in voluspa_template.values())} mod entries across '
          f'{len(voluspa_template)} skills')

    # Emit.
    lines: list[str] = []
    lines.append('-- ============================================================')
    lines.append('-- tokko_voluspa_mods.sql')
    lines.append('--')
    lines.append('-- Populates item_mods for the Tokko (15 gold marks) and Voluspa')
    lines.append('-- (12 gold marks) weapon lines sold by the gold vendor in')
    lines.append('-- modules/custom/lua/gear_progression_catalog.lua. Upstream LSB')
    lines.append('-- shipped these with base DMG/Delay set but empty item_mods,')
    lines.append('-- making them dead content (players grind gold marks, get a')
    lines.append('-- weapon with zero stat bonuses).')
    lines.append('--')
    lines.append('-- Strategy: per-skill stat templates calibrated below REMA III /')
    lines.append('-- Aeonic but above the Arasy entry line. Tokko = Voluspa + small')
    lines.append('-- additive bonus (~15-20% stat upgrade) to reflect the 25% cost')
    lines.append('-- premium.')
    lines.append('--')
    lines.append('-- INSERT IGNORE: re-runnable, preserves any existing mod rows.')
    lines.append('-- ============================================================')
    lines.append('')

    SKILL_NAMES = {1:'H2H', 2:'Dagger', 3:'Sword', 4:'Great Sword', 5:'Axe',
                   6:'Great Axe', 7:'Scythe', 8:'Polearm', 9:'Katana',
                   10:'Great Katana', 11:'Club', 12:'Staff',
                   25:'Archery', 26:'Marksmanship'}

    insert_count = 0
    skipped_no_template = 0
    for item_id, name, skill in items:
        template = voluspa_template.get(skill)
        if template is None:
            skipped_no_template += 1
            continue

        is_tokko = name.startswith('tokko')
        tier_label = 'Tokko (15 marks)' if is_tokko else 'Voluspa (12 marks)'
        skill_name = SKILL_NAMES.get(skill, f'skill {skill}')

        lines.append(f'-- {tier_label} — {skill_name}: {name}')
        for mod_id, base_value in sorted(template.items()):
            value = base_value + (tokko_bump.get(mod_id, 0) if is_tokko else 0)
            if value == 0:
                continue
            mod_label = name_by_id.get(mod_id, f'mod{mod_id}')
            lines.append(
                f'INSERT IGNORE INTO `item_mods` VALUES ({item_id}, {mod_id}, {value});   '
                f'-- {mod_label}'
            )
            insert_count += 1
        lines.append('')

    # Emit into /sql/ with zz_ prefix so the file loads AFTER item_mods.sql
    # in dbtool's full update path. See module docstring for the rationale.
    out_path = REPO_ROOT / 'sql' / 'zz_tokko_voluspa_mods.sql'
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text('\n'.join(lines), encoding='utf-8')
    print(f'Wrote {out_path}')
    print(f'  {insert_count} INSERTs across {len(items) - skipped_no_template} weapons')
    if skipped_no_template:
        print(f'  (skipped {skipped_no_template} with no template — likely ammo/grip/shield)')
    return 0


if __name__ == '__main__':
    sys.exit(main())
