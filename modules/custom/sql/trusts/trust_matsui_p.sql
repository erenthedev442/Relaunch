-- =====================================================================
-- trust_matsui_p.sql  --  Trust: Matsui-P (Void Keeper capstone)
-- Spell 1021 / pool 6021. Unlocked at Void Keeper when all 120 roster
-- trusts are collected (50M gil). Scales like a max Fellow; at master
-- level 99 his outgoing damage cap is 149,999.
-- =====================================================================

REPLACE INTO spell_list
    (spellid, name,      jobs, `group`, family, element, zonemisc, validTargets,
     skill, mpCost, castTime, recastTime, message, magicBurstMessage,
     animation, animationTime, AOE, base, multiplier, CE, VE,
     requirements, spell_range, radius, content_tag)
VALUES
    (1021, 'matsui_p', '', 8, 0, 7, 0, 1,
     0, 0, 2000, 240000, 0, 0,
     939, 1500, 0, 0, 1.00, 0, 0,
     0, 0, 0, NULL);

DELETE FROM mob_spell_lists WHERE spell_list_id = 6021;
INSERT INTO mob_spell_lists
    (spell_list_name, spell_list_id, spell_id, min_level, max_level)
VALUES
    ('matsui_p', 6021, 144,  12, 255),
    ('matsui_p', 6021, 145,  30, 255),
    ('matsui_p', 6021, 146,  55, 255),
    ('matsui_p', 6021, 147,  80, 255),
    ('matsui_p', 6021, 148,  99, 255),
    ('matsui_p', 6021, 849, 100, 255);

REPLACE INTO mob_skill_lists (skill_list_name, skill_list_id, mob_skill_id)
VALUES ('matsui_p', 6021, 3740),
       ('matsui_p', 6021, 3743),
       ('matsui_p', 6021, 202);

REPLACE INTO mob_pools
    (poolid, name,       packet_name, speciesid, modelid,
     mJob, sJob, cmbSkill, cmbDelay, cmbDmgMult,
     behavior, aggro, true_detection, links, mobType, immunity,
     name_prefix, flag, entityFlags, animationsub, hasSpellScript,
     spellList, namevis, roamflag, skill_list_id, resist_id,
     modelSize, modelHitboxSize)
VALUES
    (6021, 'matsui_p', 'Matsui-P', 246, 3121,
     12, 4, 25, 240, 300,
     0, 0, 0, 0, 0, 0,
     32, 0, 3, 0, 0,
     6021, 0, 0, 6021, 153,
     1, 12);
