-- =====================================================================
-- trust_matsui_p.sql  --  Trust: Matsui-P (Void Keeper capstone)
-- Spell 1003 / pool 6003. CLIENT spell ID 1003 = "Matsui-P".
-- Look 0x0000310C = model 3121 (trust-era size=0 look). Always available here.
-- NIN/BLM katana + San ninjutsu / T1 nukes / Utsusemi / utility.
-- =====================================================================

REPLACE INTO spell_list
    (spellid, name,      jobs, `group`, family, element, zonemisc, validTargets,
     skill, mpCost, castTime, recastTime, message, magicBurstMessage,
     animation, animationTime, AOE, base, multiplier, CE, VE,
     requirements, spell_range, radius, content_tag)
VALUES
    (1003, 'matsui_p', 0x01010101010101010101010101010101010101010101, 8, 0, 7, 0, 1,
     0, 0, 2000, 240000, 0, 0,
     939, 1500, 0, 0, 1.00, 0, 0,
     0, 0, 0, NULL);

-- Clear old wrong slot if previously applied as 1021/6021.
DELETE FROM spell_list WHERE spellid = 1021 AND name = 'matsui_p';
DELETE FROM mob_pools WHERE poolid = 6021 AND name = 'matsui_p';
DELETE FROM mob_spell_lists WHERE spell_list_id = 6021;
DELETE FROM mob_skill_lists WHERE skill_list_id = 6021;

DELETE FROM mob_spell_lists WHERE spell_list_id = 6003;
INSERT INTO mob_spell_lists
    (spell_list_name, spell_list_id, spell_id, min_level, max_level)
VALUES
    -- Utsusemi
    ('matsui_p', 6003, 338,   1, 255), -- utsusemi_ichi
    ('matsui_p', 6003, 339,  37, 255), -- utsusemi_ni
    ('matsui_p', 6003, 340,  99, 255), -- utsusemi_san
    -- Elemental Ninjutsu San (MB)
    ('matsui_p', 6003, 322,  90, 255), -- katon_san
    ('matsui_p', 6003, 325,  90, 255), -- hyoton_san
    ('matsui_p', 6003, 328,  90, 255), -- huton_san
    ('matsui_p', 6003, 331,  90, 255), -- doton_san
    ('matsui_p', 6003, 334,  90, 255), -- raiton_san
    ('matsui_p', 6003, 337,  90, 255), -- suiton_san
    -- Single-target elemental nukes I
    ('matsui_p', 6003, 144,   1, 255), -- fire
    ('matsui_p', 6003, 149,   1, 255), -- blizzard
    ('matsui_p', 6003, 154,   1, 255), -- aero
    ('matsui_p', 6003, 159,   1, 255), -- stone
    ('matsui_p', 6003, 164,   1, 255), -- thunder
    ('matsui_p', 6003, 169,   1, 255), -- water
    -- Utility
    ('matsui_p', 6003, 235,  24, 255), -- burn
    ('matsui_p', 6003, 247,  25, 255), -- aspir
    ('matsui_p', 6003, 252,  45, 255), -- stun
    ('matsui_p', 6003, 319,  60, 255), -- aisha_ichi
    ('matsui_p', 6003, 507,  60, 255), -- myoshu_ichi
    ('matsui_p', 6003, 508,  60, 255), -- yurin_ichi
    ('matsui_p', 6003, 509,  60, 255), -- kakka_ichi
    ('matsui_p', 6003, 510,  88, 255); -- migawari_ichi

DELETE FROM mob_skill_lists WHERE skill_list_id = 6003;
INSERT INTO mob_skill_lists (skill_list_name, skill_list_id, mob_skill_id)
VALUES
    ('matsui_p', 6003, 128), -- Blade: Rin
    ('matsui_p', 6003, 129), -- Blade: Retsu
    ('matsui_p', 6003, 133), -- Blade: Ei
    ('matsui_p', 6003, 134), -- Blade: Jin
    ('matsui_p', 6003, 135), -- Blade: Ten
    ('matsui_p', 6003, 136), -- Blade: Ku
    ('matsui_p', 6003, 138), -- Blade: Kamu
    ('matsui_p', 6003, 140), -- Blade: Hi
    ('matsui_p', 6003, 141); -- Blade: Shun

REPLACE INTO mob_pools
    (poolid, name,       packet_name, speciesid, modelid,
     mJob, sJob, cmbSkill, cmbDelay, cmbDmgMult,
     behavior, aggro, true_detection, links, mobType, immunity,
     name_prefix, flag, entityFlags, animationsub, hasSpellScript,
     spellList, namevis, roamflag, skill_list_id, resist_id,
     modelSize, modelHitboxSize)
VALUES
    -- model 3121 = 0x0C31 LE -> bytes 31 0C (trust-era size=0 look).
    -- NIN/BLM, Katana, high cmbDmgMult for Void Keeper AA identity.
    (6003, 'matsui_p', 'Matsui-P', 297, UNHEX('0000310C00000000000000000000000000000000'),
     13, 4, 9, 210, 300,
     0, 0, 0, 0, 0, 0,
     32, 0, 3, 0, 0,
     6003, 0, 0, 6003, 153,
     1, 12);
