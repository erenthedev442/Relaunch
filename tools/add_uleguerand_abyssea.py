#!/usr/bin/env python3
"""
add_uleguerand_abyssea.py

Wire Abyssea-Uleguerand's ??? pop points into the custom AbysseaMarks system,
the same way tools/fix_abyssea_triggers.py did for Misareaux/Vunkerl.

Uleguerand shipped as STUBS: every qmN.lua has a commented-out
`xi.abyssea.qmOnTrigger(...)` (so the ??? does nothing) and IDs.lua has an
empty `mob = {}` block. This script:

  1. Populates scripts/zones/Abyssea-Uleguerand/IDs.lua's mob block with the
     14 NM constants (GetFirstID lookups; the 4 multi-pop NMs use *_OFFSET).
  2. Rewrites each qm1..qm22 to call qmOnTrigger with the real mob id, so the
     AbysseaMarks.marksPopHook intercepts and offers the Hunt Marks pop.

NM -> qm mapping + mob-id offsets were read from the live DB (mob_spawn_points,
zone 253) and the per-qm "-- Spawns <NM>" header comments. The 4 triple-???
NMs have mob ids spaced +0/+4/+8 (interleaved), identical to Vunkerl.

Idempotent-ish: re-running rewrites the qm files with identical content and
skips IDs.lua once it already has GetFirstID constants.

Run from the repo root:  python tools/add_uleguerand_abyssea.py
"""

import os
import re

BASE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'scripts', 'zones')

ZONE_NAME  = 'Abyssea-Uleguerand'
ZONE_CONST = 'ABYSSEA_ULEGUERAND'

# qm -> (display name for the comment, mob-id expression used in qmOnTrigger)
ULEGUERAND_MOBS = {
    'qm1':  ('Ironclad Triturator', 'ID.mob.IRONCLAD_TRITURATOR'),
    'qm2':  ('Dhorme Khimaira',     'ID.mob.DHORME_KHIMAIRA'),
    'qm3':  ('Blanga',              'ID.mob.BLANGA'),
    'qm4':  ('Yaguarogui',          'ID.mob.YAGUAROGUI'),
    'qm5':  ('Koghatu',             'ID.mob.KOGHATU'),
    'qm6':  ('Upas-Kamuy',          'ID.mob.UPAS_KAMUY'),
    'qm7':  ('Veri Selen',          'ID.mob.VERI_SELEN'),
    'qm8':  ('Anemic Aloysius',     'ID.mob.ANEMIC_ALOYSIUS'),
    'qm9':  ('Chillwing Hwitti',    'ID.mob.CHILLWING_HWITTI'),
    'qm10': ('Audumbla',            'ID.mob.AUDUMBLA'),
    # 4 NMs x 3 ??? copies each (mob ids interleaved, +0/+4/+8).
    'qm11': ('Pantokrator',         'ID.mob.PANTOKRATOR_OFFSET + 0'),
    'qm12': ('Apademak',            'ID.mob.APADEMAK_OFFSET + 0'),
    'qm13': ('Isgebind',            'ID.mob.ISGEBIND_OFFSET + 0'),
    'qm14': ('Resheph',             'ID.mob.RESHEPH_OFFSET + 0'),
    'qm15': ('Pantokrator',         'ID.mob.PANTOKRATOR_OFFSET + 4'),
    'qm16': ('Apademak',            'ID.mob.APADEMAK_OFFSET + 4'),
    'qm17': ('Isgebind',            'ID.mob.ISGEBIND_OFFSET + 4'),
    'qm18': ('Resheph',             'ID.mob.RESHEPH_OFFSET + 4'),
    'qm19': ('Pantokrator',         'ID.mob.PANTOKRATOR_OFFSET + 8'),
    'qm20': ('Apademak',            'ID.mob.APADEMAK_OFFSET + 8'),
    'qm21': ('Isgebind',            'ID.mob.ISGEBIND_OFFSET + 8'),
    'qm22': ('Resheph',             'ID.mob.RESHEPH_OFFSET + 8'),
}

ULEGUERAND_IDS_MOB_BLOCK = """\
    mob =
    {
        IRONCLAD_TRITURATOR = GetFirstID('Ironclad_Triturator'),
        DHORME_KHIMAIRA     = GetFirstID('Dhorme_Khimaira'),
        BLANGA              = GetFirstID('Blanga'),
        YAGUAROGUI          = GetFirstID('Yaguarogui'),
        KOGHATU             = GetFirstID('Koghatu'),
        UPAS_KAMUY          = GetFirstID('Upas-Kamuy'),
        VERI_SELEN          = GetFirstID('Veri_Selen'),
        ANEMIC_ALOYSIUS     = GetFirstID('Anemic_Aloysius'),
        CHILLWING_HWITTI    = GetFirstID('Chillwing_Hwitti'),
        AUDUMBLA            = GetFirstID('Audumbla'),
        PANTOKRATOR_OFFSET  = GetFirstID('Pantokrator'),  -- 3 copies: +0, +4, +8
        APADEMAK_OFFSET     = GetFirstID('Apademak'),      -- 3 copies: +0, +4, +8
        ISGEBIND_OFFSET     = GetFirstID('Isgebind'),      -- 3 copies: +0, +4, +8
        RESHEPH_OFFSET      = GetFirstID('Resheph'),       -- 3 copies: +0, +4, +8
    },"""

POS_PATTERN = re.compile(r'-- !pos (.+)')
# Tolerate CRLF or LF in the working tree.
EMPTY_MOB_PATTERN = re.compile(r'    mob =\r?\n    \{\r?\n    \},')


def write_stub_qm(fpath, qm_name, mob_display, mob_id_expr):
    with open(fpath, 'r', newline='', encoding='utf-8') as f:
        old = f.read()
    m = POS_PATTERN.search(old)
    pos = m.group(1).strip() if m else '? ? ? ?'

    content = (
        f'-----------------------------------\n'
        f'-- Zone: {ZONE_NAME}\n'
        f'--  NPC: {qm_name} (???)\n'
        f'-- Spawns {mob_display}\n'
        f'-- !pos {pos}\n'
        f'-----------------------------------\n'
        f'local ID = zones[xi.zone.{ZONE_CONST}]\n'
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


def fix_ids_lua(ids_path):
    with open(ids_path, 'r', newline='', encoding='utf-8') as f:
        content = f.read()
    if 'GetFirstID' in content:
        print('  IDs.lua already has mob constants -- skipped')
        return
    new_content = EMPTY_MOB_PATTERN.sub(ULEGUERAND_IDS_MOB_BLOCK, content)
    if new_content == content:
        print('  WARNING: IDs.lua empty-mob pattern not matched -- check manually')
        return
    with open(ids_path, 'w', newline='', encoding='utf-8') as f:
        f.write(new_content)
    print('  Updated: IDs.lua mob block populated')


def main():
    zone_dir = os.path.join(BASE, ZONE_NAME)
    npc_dir  = os.path.join(zone_dir, 'npcs')
    if not os.path.isdir(npc_dir):
        print(f'Zone npcs dir not found: {npc_dir}')
        return

    print('=' * 60)
    print(f'Wiring {ZONE_NAME} ??? pops into AbysseaMarks')
    print('=' * 60)

    fix_ids_lua(os.path.join(zone_dir, 'IDs.lua'))
    for qm, (mob_display, mob_id) in ULEGUERAND_MOBS.items():
        fpath = os.path.join(npc_dir, f'{qm}.lua')
        if not os.path.exists(fpath):
            print(f'  MISSING: {fpath}')
            continue
        write_stub_qm(fpath, qm, mob_display, mob_id)

    print('\nDone.')


if __name__ == '__main__':
    main()
