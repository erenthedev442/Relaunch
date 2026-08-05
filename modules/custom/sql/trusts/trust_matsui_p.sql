-- =====================================================================
-- trust_matsui_p.sql  --  Trust: Matsui-P (Void Keeper capstone)
-- Spell 1003 / pool 6003. CLIENT spell ID 1003 = "Matsui-P".
-- Look 0x0000310C = model 3121 (trust-era size=0 look).
--
-- RESTORED to pre-round5 known-good summon config (SAM/BLM + Final Exam
-- kit). Round5 NIN/katana + later Exc_S/Makki overlays R0'd the client;
-- spell 1003 + this pool shape is the last proven summonable state.
-- =====================================================================

-- Snapshot Exc_S-overlay Matsui owners BEFORE we rename spell 1004.
-- Only runs while 1004 is still named matsui_p (one-shot leave of overlay era).
CREATE TEMPORARY TABLE IF NOT EXISTS _matsui_owners AS
    SELECT DISTINCT cv.charid
    FROM char_vars cv
    WHERE cv.varname IN ('TrustEarned_1003', 'TrustEarned_1004')
      AND cv.value = 1
      AND EXISTS (SELECT 1 FROM spell_list WHERE spellid = 1004 AND name = 'matsui_p')
    UNION
    SELECT DISTINCT cs.charid
    FROM char_spells cs
    WHERE cs.spellid = 1003
    UNION
    SELECT DISTINCT cs.charid
    FROM char_spells cs
    WHERE cs.spellid = 1004
      AND EXISTS (SELECT 1 FROM spell_list WHERE spellid = 1004 AND name = 'matsui_p');

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

-- Clear wrong slots (1021 experiment; matsui rows left on 6004).
DELETE FROM spell_list WHERE spellid = 1021 AND name = 'matsui_p';
DELETE FROM mob_pools WHERE poolid = 6021 AND name = 'matsui_p';
DELETE FROM mob_spell_lists WHERE spell_list_id = 6021;
DELETE FROM mob_skill_lists WHERE skill_list_id = 6021;
DELETE FROM mob_spell_lists WHERE spell_list_id = 6004 AND spell_list_name = 'matsui_p';
DELETE FROM mob_skill_lists WHERE skill_list_id = 6004 AND skill_list_name = 'matsui_p';

-- Restore retail Excenmille (S). round5_excenmille_s.sql retunes WAR/PLD + GS.
REPLACE INTO spell_list
    (spellid, name,           jobs, `group`, family, element, zonemisc, validTargets,
     skill, mpCost, castTime, recastTime, message, magicBurstMessage,
     animation, animationTime, AOE, base, multiplier, CE, VE,
     requirements, spell_range, radius, content_tag)
VALUES
    (1004, 'excenmille_s', 0x01010101010101010101010101010101010101010101, 8, 0, 7, 0, 1,
     0, 0, 2000, 240000, 0, 0,
     939, 1500, 0, 0, 1.00, 0, 0,
     0, 0, 0, NULL);

REPLACE INTO mob_pools
    (poolid, name,           packet_name, speciesid, modelid,
     mJob, sJob, cmbSkill, cmbDelay, cmbDmgMult,
     behavior, aggro, true_detection, links, mobType, immunity,
     name_prefix, flag, entityFlags, animationsub, hasSpellScript,
     spellList, namevis, roamflag, skill_list_id, resist_id,
     modelSize, modelHitboxSize)
VALUES
    (6004, 'excenmille_s', 'Excenmille', 293, UNHEX('0000EC0B00000000000000000000000000000000'),
     1, 7, 4, 240, 100,
     0, 0, 0, 0, 0, 0,
     32, 0, 3, 0, 0,
     0, 0, 0, 1119, 145,
     NULL, NULL);

-- Move overlay-era Matsui owners to spell 1003 (no-op when _matsui_owners empty).
DELETE FROM char_spells
 WHERE spellid = 1004
   AND charid IN (SELECT charid FROM _matsui_owners);
INSERT IGNORE INTO char_spells (charid, spellid)
    SELECT charid, 1003 FROM _matsui_owners;
DELETE FROM char_vars
 WHERE varname IN ('TrustEarned_1003', 'TrustEarned_1004')
   AND charid IN (SELECT charid FROM _matsui_owners);
INSERT INTO char_vars (charid, varname, value, expiry)
    SELECT charid, 'TrustEarned_1003', 1, 0 FROM _matsui_owners;
DROP TEMPORARY TABLE IF EXISTS _matsui_owners;

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
