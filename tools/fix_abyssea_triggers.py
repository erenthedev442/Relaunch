#!/usr/bin/env python3
"""
fix_abyssea_triggers.py
Batch-fix Abyssea trade-pop and stub ??? scripts so they all offer
the AbysseaMarks pop menu instead of doing nothing.

Named zones (Konschtat/Tahrongi/La_Theine/Attohwa/Altepa/Grauberg):
  onTrigger currently passes mobId=0 -> extract real mob ID from onTrade
  and inject it with empty KI list: qmOnTrigger(player, npc, ID.mob.X, {}, {items})

Misareaux / Vunkerl:
  onTrigger is a commented-out stub with no mob ID.
  Rewrite each qmN.lua with the real mob ID from the hardcoded mapping below,
  add local ID = zones[xi.zone.ZONE] header, and add mob constants to IDs.lua.
"""

import re
import os
import sys

BASE = r'D:\server\scripts\zones'

# ── Named zones ────────────────────────────────────────────────────────────────

NAMED_ZONES = [
    'Abyssea-Konschtat',
    'Abyssea-Tahrongi',
    'Abyssea-La_Theine',
    'Abyssea-Attohwa',
    'Abyssea-Altepa',
    'Abyssea-Grauberg',
]

TRIGGER_PATTERN = re.compile(
    r'(xi\.abyssea\.qmOnTrigger\(player,\s*npc,\s*)0,\s*0,\s*\{'
)
TRADE_MOB_PATTERN = re.compile(
    r'xi\.abyssea\.qmOnTrade\(player,\s*npc,\s*trade,\s*(ID\.mob\.\w+)'
)

def fix_named_zone(zone_dir):
    npc_dir = os.path.join(zone_dir, 'npcs')
    if not os.path.isdir(npc_dir):
        print(f'  (no npcs dir)')
        return 0
    changed = 0
    for fname in sorted(os.listdir(npc_dir)):
        if not fname.startswith('qm_') or not fname.endswith('.lua'):
            continue
        fpath = os.path.join(npc_dir, fname)
        with open(fpath, 'r', newline='', encoding='utf-8') as f:
            content = f.read()
        if not TRIGGER_PATTERN.search(content):
            continue  # KI-pop or already fixed
        m = TRADE_MOB_PATTERN.search(content)
        if not m:
            print(f'  WARNING: {fname} has 0,0 trigger but no mob ID in onTrade — skipped')
            continue
        mob_id = m.group(1)
        new_content = TRIGGER_PATTERN.sub(
            lambda mo: mo.group(1) + mob_id + ', {}, {',
            content
        )
        if new_content != content:
            with open(fpath, 'w', newline='', encoding='utf-8') as f:
                f.write(new_content)
            print(f'  Fixed: {fname}  ->  {mob_id}')
            changed += 1
    return changed

# ── Misareaux stub scripts ─────────────────────────────────────────────────────

MISAREAUX_MOBS = {
    'qm1':  ('Minax Bugard',          'ID.mob.MINAX_BUGARD'),
    'qm2':  ('Sirrush',               'ID.mob.SIRRUSH'),
    'qm3':  ('Funereal Apkallu',      'ID.mob.FUNEREAL_APKALLU'),
    'qm4':  ('Manohra',               'ID.mob.MANOHRA'),
    'qm5':  ('Cep-Kamuy',             'ID.mob.CEP_KAMUY'),
    'qm6':  ('Ironclad Observer',     'ID.mob.IRONCLAD_OBSERVER'),
    'qm7':  ('Nehebkau',              'ID.mob.NEHEBKAU'),
    'qm8':  ('Avalerion',             'ID.mob.AVALERION'),
    'qm9':  ('Karkatakam',            'ID.mob.KARKATAKAM'),
    'qm10': ('Nonno',                 'ID.mob.NONNO'),
    'qm11': ('Tuskertrap',            'ID.mob.TUSKERTRAP'),
    'qm12': ('Npfundlwa',             'ID.mob.NPFUNDLWA'),
    'qm13': ('Cirein-croin',          'ID.mob.CIREIN_CROIN_OFFSET + 0'),
    'qm14': ('Amhuluk',               'ID.mob.AMHULUK_OFFSET + 0'),
    'qm15': ('Sobek',                 'ID.mob.SOBEK_OFFSET + 0'),
    'qm16': ('Ironclad Pulverizer',   'ID.mob.IRONCLAD_PULVERIZER_OFFSET + 0'),
    'qm17': ('Cirein-croin',          'ID.mob.CIREIN_CROIN_OFFSET + 5'),
    'qm18': ('Amhuluk',               'ID.mob.AMHULUK_OFFSET + 5'),
    'qm19': ('Sobek',                 'ID.mob.SOBEK_OFFSET + 5'),
    'qm20': ('Ironclad Pulverizer',   'ID.mob.IRONCLAD_PULVERIZER_OFFSET + 5'),
    'qm21': ('Cirein-croin',          'ID.mob.CIREIN_CROIN_OFFSET + 10'),
    'qm22': ('Amhuluk',               'ID.mob.AMHULUK_OFFSET + 10'),
    'qm23': ('Sobek',                 'ID.mob.SOBEK_OFFSET + 10'),
    'qm24': ('Ironclad Pulverizer',   'ID.mob.IRONCLAD_PULVERIZER_OFFSET + 10'),
}

MISAREAUX_IDS_MOB_BLOCK = """\
    mob =
    {
        MINAX_BUGARD               = GetFirstID('Minax_Bugard'),
        SIRRUSH                    = GetFirstID('Sirrush'),
        FUNEREAL_APKALLU           = GetFirstID('Funereal_Apkallu'),
        MANOHRA                    = GetFirstID('Manohra'),
        CEP_KAMUY                  = GetFirstID('Cep-Kamuy'),
        IRONCLAD_OBSERVER          = GetFirstID('Ironclad_Observer'),
        NEHEBKAU                   = GetFirstID('Nehebkau'),
        AVALERION                  = GetFirstID('Avalerion'),
        KARKATAKAM                 = GetFirstID('Karkatakam'),
        NONNO                      = GetFirstID('Nonno'),
        TUSKERTRAP                 = GetFirstID('Tuskertrap'),
        NPFUNDLWA                  = GetFirstID('Npfundlwa'),
        CIREIN_CROIN_OFFSET        = GetFirstID('Cirein-croin'),    -- 3 copies: +0, +5, +10
        AMHULUK_OFFSET             = GetFirstID('Amhuluk'),         -- 3 copies: +0, +5, +10
        SOBEK_OFFSET               = GetFirstID('Sobek'),           -- 3 copies: +0, +5, +10
        IRONCLAD_PULVERIZER_OFFSET = GetFirstID('Ironclad_Pulverizer'), -- 3 copies: +0, +5, +10
    },"""

# ── Vunkerl stub scripts ───────────────────────────────────────────────────────

VUNKERL_MOBS = {
    'qm1':  ('Khalkotaur',             'ID.mob.KHALKOTAUR'),
    'qm2':  ('Quasimodo',              'ID.mob.QUASIMODO'),
    'qm3':  ('Iku-Turso',              'ID.mob.IKU_TURSO'),
    'qm4':  ('Dvalinn',                'ID.mob.DVALINN'),
    'qm5':  ('Kadraeth the Hatespawn', 'ID.mob.KADRAETH_THE_HATESPAWN'),
    'qm6':  ('Rakshas',                'ID.mob.RAKSHAS'),
    'qm7':  ('Seps',                   'ID.mob.SEPS'),
    'qm8':  ('Xan',                    'ID.mob.XAN'),
    'qm9':  ('Chhir Batti',            'ID.mob.CHHIR_BATTI'),
    'qm10': ('Armillaria',             'ID.mob.ARMILLARIA'),
    'qm11': ('Pascerpot',              'ID.mob.PASCERPOT'),
    'qm12': ('Gnawtooth Gary',         'ID.mob.GNAWTOOTH_GARY'),
    'qm13': ('Bukhis',                 'ID.mob.BUKHIS_OFFSET + 0'),
    'qm14': ('Sedna',                  'ID.mob.SEDNA_OFFSET + 0'),
    'qm15': ('Durinn',                 'ID.mob.DURINN_OFFSET + 0'),
    'qm16': ('Karkadann',              'ID.mob.KARKADANN_OFFSET + 0'),
    'qm17': ('Bukhis',                 'ID.mob.BUKHIS_OFFSET + 4'),
    'qm18': ('Sedna',                  'ID.mob.SEDNA_OFFSET + 4'),
    'qm19': ('Durinn',                 'ID.mob.DURINN_OFFSET + 4'),
    'qm20': ('Karkadann',              'ID.mob.KARKADANN_OFFSET + 4'),
    'qm21': ('Bukhis',                 'ID.mob.BUKHIS_OFFSET + 8'),
    'qm22': ('Sedna',                  'ID.mob.SEDNA_OFFSET + 8'),
    'qm23': ('Durinn',                 'ID.mob.DURINN_OFFSET + 8'),
    'qm24': ('Karkadann',              'ID.mob.KARKADANN_OFFSET + 8'),
}

VUNKERL_IDS_MOB_BLOCK = """\
    mob =
    {
        KHALKOTAUR               = GetFirstID('Khalkotaur'),
        QUASIMODO                = GetFirstID('Quasimodo'),
        IKU_TURSO                = GetFirstID('Iku-Turso'),
        DVALINN                  = GetFirstID('Dvalinn'),
        KADRAETH_THE_HATESPAWN   = GetFirstID('Kadraeth_the_Hatespawn'),
        RAKSHAS                  = GetFirstID('Rakshas'),
        SEPS                     = GetFirstID('Seps'),
        XAN                      = GetFirstID('Xan'),
        CHHIR_BATTI              = GetFirstID('Chhir_Batti'),
        ARMILLARIA               = GetFirstID('Armillaria'),
        PASCERPOT                = GetFirstID('Pascerpot'),
        GNAWTOOTH_GARY           = GetFirstID('Gnawtooth_Gary'),
        BUKHIS_OFFSET            = GetFirstID('Bukhis'),     -- 3 copies: +0, +4, +8
        SEDNA_OFFSET             = GetFirstID('Sedna'),      -- 3 copies: +0, +4, +8
        DURINN_OFFSET            = GetFirstID('Durinn'),     -- 3 copies: +0, +4, +8
        KARKADANN_OFFSET         = GetFirstID('Karkadann'),  -- 3 copies: +0, +4, +8
    },"""

# ── Shared helpers ─────────────────────────────────────────────────────────────

POS_PATTERN = re.compile(r'-- !pos (.+)')
EMPTY_MOB_PATTERN = re.compile(r'    mob =\n    \{\n    \},', re.MULTILINE)


def write_stub_qm(fpath, zone_name, zone_const, qm_name, mob_display, mob_id_expr):
    with open(fpath, 'r', newline='', encoding='utf-8') as f:
        old = f.read()
    m = POS_PATTERN.search(old)
    pos = m.group(1).strip() if m else '? ? ? ?'

    content = (
        f'-----------------------------------\n'
        f'-- Zone: {zone_name}\n'
        f'--  NPC: {qm_name} (???)\n'
        f'-- Spawns {mob_display}\n'
        f'-- !pos {pos}\n'
        f'-----------------------------------\n'
        f'local ID = zones[xi.zone.{zone_const}]\n'
        f'-----------------------------------\n'
        f'---@type TNpcEntity\n'
        f'local entity = {{}}\n'
        f'\n'
        f'entity.onTrade = function(player, npc, trade)\n'
        f'end\n'
        f'\n'
        f'entity.onTrigger = function(player, npc)\n'
        f'    xi.abyssea.qmOnTrigger(player, npc, {mob_id_expr}, {{}})\n'
        f'end\n'
        f'\n'
        f'return entity\n'
    )
    with open(fpath, 'w', newline='', encoding='utf-8') as f:
        f.write(content)
    print(f'  Written: {qm_name}.lua  ->  {mob_id_expr}')


def fix_ids_lua(ids_path, mob_block):
    with open(ids_path, 'r', newline='', encoding='utf-8') as f:
        content = f.read()
    if 'GetFirstID' in content:
        print(f'  IDs.lua already has mob constants — skipped')
        return
    new_content = EMPTY_MOB_PATTERN.sub(mob_block, content)
    if new_content == content:
        print(f'  WARNING: IDs.lua mob pattern not matched — check manually')
        return
    with open(ids_path, 'w', newline='', encoding='utf-8') as f:
        f.write(new_content)
    print(f'  Updated: IDs.lua mob block populated')


# ── Main ───────────────────────────────────────────────────────────────────────

def main():
    print('=' * 60)
    print('Fixing named zone trade-pop ??? scripts')
    print('=' * 60)
    total = 0
    for zone in NAMED_ZONES:
        zone_dir = os.path.join(BASE, zone)
        print(f'\n{zone}:')
        if not os.path.isdir(zone_dir):
            print(f'  Zone directory not found')
            continue
        total += fix_named_zone(zone_dir)
    print(f'\nTotal named-zone files fixed: {total}')

    print()
    print('=' * 60)
    print('Fixing Abyssea-Misareaux stub scripts + IDs.lua')
    print('=' * 60)
    mis_dir = os.path.join(BASE, 'Abyssea-Misareaux')
    npc_dir = os.path.join(mis_dir, 'npcs')
    fix_ids_lua(os.path.join(mis_dir, 'IDs.lua'), MISAREAUX_IDS_MOB_BLOCK)
    for qm, (mob_display, mob_id) in MISAREAUX_MOBS.items():
        fpath = os.path.join(npc_dir, f'{qm}.lua')
        if not os.path.exists(fpath):
            print(f'  MISSING: {fpath}')
            continue
        write_stub_qm(fpath, 'Abyssea-Misareaux', 'ABYSSEA_MISAREAUX', qm, mob_display, mob_id)

    print()
    print('=' * 60)
    print('Fixing Abyssea-Vunkerl stub scripts + IDs.lua')
    print('=' * 60)
    vun_dir = os.path.join(BASE, 'Abyssea-Vunkerl')
    npc_dir = os.path.join(vun_dir, 'npcs')
    fix_ids_lua(os.path.join(vun_dir, 'IDs.lua'), VUNKERL_IDS_MOB_BLOCK)
    for qm, (mob_display, mob_id) in VUNKERL_MOBS.items():
        fpath = os.path.join(npc_dir, f'{qm}.lua')
        if not os.path.exists(fpath):
            print(f'  MISSING: {fpath}')
            continue
        write_stub_qm(fpath, 'Abyssea-Vunkerl', 'ABYSSEA_VUNKERL', qm, mob_display, mob_id)

    print()
    print('Done.')


if __name__ == '__main__':
    main()
