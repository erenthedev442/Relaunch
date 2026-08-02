-- =====================================================================
-- trust_matsui_p.sql  --  Trust: Matsui-P (Void Keeper capstone)
-- Spell 1003 / pool 6003. CLIENT spell ID 1003 = "Matsui-P".
-- Look 0x0000310C = model 3121 (trust-era size=0 look).
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
    ('matsui_p', 6003, 144,  12, 255),
    ('matsui_p', 6003, 145,  30, 255),
    ('matsui_p', 6003, 146,  55, 255),
    ('matsui_p', 6003, 147,  80, 255),
    ('matsui_p', 6003, 148,  99, 255),
    ('matsui_p', 6003, 849, 100, 255);

DELETE FROM mob_skill_lists WHERE skill_list_id = 6003;
INSERT INTO mob_skill_lists (skill_list_name, skill_list_id, mob_skill_id)
VALUES ('matsui_p', 6003, 3740),
       ('matsui_p', 6003, 3743),
       ('matsui_p', 6003, 202);

REPLACE INTO mob_pools
    (poolid, name,       packet_name, speciesid, modelid,
     mJob, sJob, cmbSkill, cmbDelay, cmbDmgMult,
     behavior, aggro, true_detection, links, mobType, immunity,
     name_prefix, flag, entityFlags, animationsub, hasSpellScript,
     spellList, namevis, roamflag, skill_list_id, resist_id,
     modelSize, modelHitboxSize)
VALUES
    -- model 3121 = 0x0C31 LE -> bytes 31 0C (trust-era size=0 look).
    (6003, 'matsui_p', 'Matsui-P', 297, UNHEX('0000310C00000000000000000000000000000000'),
     12, 4, 25, 240, 300,
     0, 0, 0, 0, 0, 0,
     32, 0, 3, 0, 0,
     6003, 0, 0, 6003, 153,
     1, 12);
