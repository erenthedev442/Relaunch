"""
Reorganize GM Home NPC positions by player progression.
Run once: python tools/reorganize_gm_home_npcs.py
"""
import sys

BASE = 'D:/server/modules/custom/lua/'

def edit_file(fname, replacements):
    path = BASE + fname
    with open(path, encoding='utf-8') as f:
        text = f.read()
    orig = text
    for old, new in replacements:
        if old not in text:
            print(f'MISS in {fname}: {repr(old[:60])}', file=sys.stderr)
            continue
        text = text.replace(old, new, 1)
    if text == orig:
        print(f'NO CHANGE: {fname}')
    else:
        with open(path, 'w', encoding='utf-8', newline='\n') as f:
            f.write(text)
        print(f'OK: {fname}')

# ── z=-5  New Player Setup ──────────────────────────────────────────────

edit_file('gear_moogle.lua', [
    ('        z          =  -10.000,', '        z          =   -5.000,'),
])

edit_file('mog_moogle.lua', [
    ('        x          =  7.500,', '        x          = -1.500,'),
    ('        z          = -10.000,', '        z          =  -5.000,'),
])

edit_file('Character_Upgrader.lua', [
    ('        x          = -1.500,', '        x          =  1.500,'),
    ('        z          = -10.000,', '        z          =  -5.000,'),
])

edit_file('gm_home_homepoint.lua', [
    ('        x          =  -3.000,', '        x          =   4.500,'),
    ('        z          = -15.000,', '        z          =  -5.000,'),
])

# ── z=-10  Leveling & Travel ────────────────────────────────────────────

edit_file('ExpCamp_Moogle.lua', [
    ('        x          =   0.000,', '        x          =  -4.500,'),
    ('        z          = -15.000,', '        z          = -10.000,'),
])

edit_file('gil_warp_npc_catalog.lua', [
    ('catalog.npcPos    = { x = 3.000, y = 0.000, z = -15.000, rot = 128 }',
     'catalog.npcPos    = { x = -1.500, y = 0.000, z = -10.000, rot = 128 }'),
])

edit_file('player_trusts_catalog.lua', [
    ('    x        =  -7.500,', '    x        =   7.500,'),
    ('    z        = -30.000,', '    z        = -10.000,'),
])

# ── z=-15  Daily Content ────────────────────────────────────────────────

edit_file('daily_board_catalog.lua', [
    ('    z        = -25.000,', '    z        = -15.000,'),
])

edit_file('weekly_hunts_catalog.lua', [
    ('    z        = -25.000,', '    z        = -15.000,'),
])

edit_file('SparksExchange.lua', [
    ('    npcPos = { x = -7.500, y = 0.000, z = -35.000, rot = 128 },',
     '    npcPos = { x =  1.500, y = 0.000, z = -15.000, rot = 128 },'),
])

edit_file('crafting_exchange_catalog.lua', [
    ('    x        =  1.500,', '    x        =  4.500,'),
    ('    z        = -30.000,', '    z        = -15.000,'),
])

# ── z=-20  Economy & Fun ────────────────────────────────────────────────

edit_file('casino_catalog.lua', [
    ('catalog.npcPos  = { x = -4.500, y = 0.000, z = -35.000, rot = 128 }  -- gambling corner, west of the Mystery Mog (x=1.5 is the Title Vendor)',
     'catalog.npcPos  = { x = -4.500, y = 0.000, z = -20.000, rot = 128 }'),
])

edit_file('gil_mystery_box_catalog.lua', [
    ('catalog.npcPos    = { x = -1.500, y = 0.000, z = -35.000, rot = 128 }',
     'catalog.npcPos    = { x = -1.500, y = 0.000, z = -20.000, rot = 128 }'),
])

edit_file('gil_title_vendor_catalog.lua', [
    ('catalog.npcPos   = { x = 1.500, y = 0.000, z = -35.000, rot = 128 }',
     'catalog.npcPos   = { x = 1.500, y = 0.000, z = -20.000, rot = 128 }'),
])

edit_file('gil_exchange_npc.lua', [
    ('    npcPos   = { x = 4.500, y = 0.000, z = -35.000, rot = 128 },',
     '    npcPos   = { x = 4.500, y = 0.000, z = -20.000, rot = 128 },'),
])

edit_file('gil_race_changer.lua', [
    ('    npcPos  = { x = 7.500, y = 0.000, z = -35.000, rot = 128 },',
     '    npcPos  = { x = 7.500, y = 0.000, z = -20.000, rot = 128 },'),
])

# ── z=-25  Gear Progression ─────────────────────────────────────────────

edit_file('Augment_Moogle.lua', [
    ('        z          = -5.000,', '        z          = -25.000,'),
])

edit_file('augment_sage_catalog.lua', [
    ('catalog.vendorPos = { x = -1.500, y = 0.000, z = -5.000, rot = 128 }',
     'catalog.vendorPos = { x = -1.500, y = 0.000, z = -25.000, rot = 128 }'),
    ('-- GM Home Progression cluster (z=-7): Gear / Augment Moogle / Augment Sage.',
     '-- GM Home Gear Progression cluster (z=-25): Augment Moogle / Augment Sage / CrossJob Trainers / Cosmetic Shop.'),
])

edit_file('CrossJob_Trainer.lua', [
    ('        z          = -5.000,', '        z          = -25.000,'),
])

edit_file('cross_job_trait_catalog.lua', [
    ('catalog.npcPos   = { x = 4.500, y = 0.000, z = -5.000, rot = 128 }  -- GM Home trainer row, east of the Ability Trainer (x=6)',
     'catalog.npcPos   = { x = 4.500, y = 0.000, z = -25.000, rot = 128 }'),
])

# ── z=-30  Infamy & Events ──────────────────────────────────────────────

edit_file('infamy_vendor_catalog.lua', [
    ('    x        =  4.500,', '    x        = -4.500,'),
    ('    z        = -20.000,', '    z        = -30.000,'),
])

edit_file('colosseum_catalog.lua', [
    ('    x        =  1.500,', '    x        = -1.500,'),
    ('    z        = -25.000,', '    z        = -30.000,'),
])

edit_file('chocobo_derby_catalog.lua', [
    ('    x        = 4.500,', '    x        = 1.500,'),
    ('    z        = -25.000,', '    z        = -30.000,'),
])

# ── z=-35  Endgame Trials ───────────────────────────────────────────────

edit_file('endless_tower.lua', [
    ('        x          = -1.500,', '        x          = -4.500,'),
    ('        z          = -30.000,', '        z          = -35.000,'),
    ('-- NPC: Endless Tower Arbiter in GM Home (zone 210), z = -30.',
     '-- NPC: Endless Tower Arbiter in GM Home (zone 210), z = -35.'),
])

edit_file('job_mastery.lua', [
    ('        x          = -4.500,', '        x          = -1.500,'),
    ('        z          = -30.000,', '        z          = -35.000,'),
    ('-- NPC: Weapon Mastery Sage in GM Home, z = -27.',
     '-- NPC: Weapon Mastery Sage in GM Home, z = -35.'),
    ('-- GM Home: place the Mastery Sage NPC at z = -30.',
     '-- GM Home: place the Mastery Sage NPC at z = -35.'),
])

edit_file('PrimeArmory_NPC.lua', [
    ('        x          = 0.000,', '        x          = 1.500,'),
    ('        z          = -20.000,', '        z          = -35.000,'),
])

edit_file('test_dummy_catalog.lua', [
    ('    x        =  7.500,', '    x        =  4.500,'),
    ('    z        = -30.000,', '    z        = -35.000,'),
])

print('All done.')
