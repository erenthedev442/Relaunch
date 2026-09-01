-- =====================================================================
-- trust_matsui_p.sql  --  Trust: Matsui-P (Void Keeper capstone)
--
-- REPURPOSES retail Excenmille (S): spell 1004 / pool 6004.
-- Same technique as Corvus→Curilla (902), Meat→Excenmille (899),
-- Gemma→Nanaa (901).
--
-- WHY NOT 1003
--   Client spell ID 1003 is the seasonal Cornelia/Matsui campaign slot.
--   Casting it R0 / disconnects outside campaign DAT windows. Putting
--   Matsui back on 1003 (the "known-good" restore) reintroduced that crash.
--
-- WHY THIS POOL SHAPE
--   Exc_S spell DAT + Exc_S look (0x00008508) are year-round safe. SAM/BLM
--   + Final Exam kit is server-side only. The menu still says Excenmille (S).
--
-- NAMETAG
--   packet_name stays Excenmille_S so the first spawn packet uses a DAT the
--   client has. Lua then renameEntity('matsui-p') — same overlay Meat/Gemma
--   use. Do NOT send the retail string 'Matsui-P': that is spell 1003's
--   campaign DAT key and R0s the client on the 0x67 trust-name packet.
--
-- APPLYING
--   1) Apply this file (deploy recurses modules/custom/sql/**/*.sql)
--   2) RESTART THE MAP SERVER (LoadTrustList is boot-only)
-- =====================================================================

-- ---- 1. Overwrite spell slot 1004 ------------------------------------
REPLACE INTO spell_list
    (spellid, name,      jobs, `group`, family, element, zonemisc, validTargets,
     skill, mpCost, castTime, recastTime, message, magicBurstMessage,
     animation, animationTime, AOE, base, multiplier, CE, VE,
     requirements, spell_range, radius, content_tag)
VALUES
    (1004, 'matsui_p', 0x01010101010101010101010101010101010101010101, 8, 0, 7, 0, 1,
     0, 0, 2000, 240000, 0, 0,
     939, 1500, 0, 0, 1.00, 0, 0,
     0, 0, 0, NULL);

-- Kill the seasonal slot so it cannot be cast / learned.
DELETE FROM spell_list WHERE spellid = 1003;
DELETE FROM mob_pools WHERE poolid = 6003;
DELETE FROM mob_spell_lists WHERE spell_list_id = 6003;
DELETE FROM mob_skill_lists WHERE skill_list_id = 6003;

-- Clear prior wrong slots.
DELETE FROM spell_list WHERE spellid = 1021 AND name = 'matsui_p';
DELETE FROM mob_pools WHERE poolid = 6021 AND name = 'matsui_p';
DELETE FROM mob_spell_lists WHERE spell_list_id = 6021;
DELETE FROM mob_skill_lists WHERE skill_list_id = 6021;

-- Migrate learned Matsui (1003 or already-overlay 1004 owners who earned Matsui).
-- Do NOT convert farmed Exc_S-only owners: only migrate charids that owned 1003
-- or have TrustEarned_1003 / TrustEarned_1004 from a prior Matsui bind.
CREATE TEMPORARY TABLE IF NOT EXISTS _matsui_owners AS
    SELECT DISTINCT charid FROM char_spells WHERE spellid = 1003
    UNION
    SELECT DISTINCT charid FROM char_vars
        WHERE varname IN ('TrustEarned_1003', 'TrustEarned_1004') AND value = 1;

DELETE FROM char_spells
 WHERE spellid = 1003
   AND charid IN (SELECT charid FROM _matsui_owners);
DELETE FROM char_spells
 WHERE spellid = 1004
   AND charid IN (SELECT charid FROM _matsui_owners);
INSERT IGNORE INTO char_spells (charid, spellid)
    SELECT charid, 1004 FROM _matsui_owners;

DELETE FROM char_vars
 WHERE varname IN ('TrustEarned_1003', 'TrustEarned_1004')
   AND charid IN (SELECT charid FROM _matsui_owners);
INSERT INTO char_vars (charid, varname, value, expiry)
    SELECT charid, 'TrustEarned_1004', 1, 0 FROM _matsui_owners;
DROP TEMPORARY TABLE IF EXISTS _matsui_owners;

-- Strip leftover 1003 from anyone else (uncastable seasonal).
DELETE FROM char_spells WHERE spellid = 1003;
DELETE FROM char_vars WHERE varname = 'TrustEarned_1003';

-- ---- 2. Spell / WS lists on pool 6004 --------------------------------
DELETE FROM mob_spell_lists WHERE spell_list_id = 6004;
INSERT INTO mob_spell_lists
    (spell_list_name, spell_list_id, spell_id, min_level, max_level)
VALUES
    ('matsui_p', 6004, 144,  12, 255),
    ('matsui_p', 6004, 145,  30, 255),
    ('matsui_p', 6004, 146,  55, 255),
    ('matsui_p', 6004, 147,  80, 255),
    ('matsui_p', 6004, 148,  99, 255),
    ('matsui_p', 6004, 849, 100, 255);

DELETE FROM mob_skill_lists WHERE skill_list_id = 6004;
INSERT INTO mob_skill_lists (skill_list_name, skill_list_id, mob_skill_id)
VALUES ('matsui_p', 6004, 3740),
       ('matsui_p', 6004, 3743),
       ('matsui_p', 6004, 202);

-- ---- 3. Pool 6004 = Matsui-P (safe look + SAM) -----------------------
REPLACE INTO mob_pools
    (poolid, name,       packet_name, speciesid, modelid,
     mJob, sJob, cmbSkill, cmbDelay, cmbDmgMult,
     behavior, aggro, true_detection, links, mobType, immunity,
     name_prefix, flag, entityFlags, animationsub, hasSpellScript,
     spellList, namevis, roamflag, skill_list_id, resist_id,
     modelSize, modelHitboxSize)
VALUES
    -- Retail Exc_S look 0x00008508 (year-round). packet_name MUST stay
    -- Excenmille_S so the spawn/0x67 DAT key is safe. Nametag is Lua overlay.
    (6004, 'matsui_p', 'Excenmille_S', 293, UNHEX('00008508000000000000000000000000000000'),
     12, 4, 25, 240, 300,
     0, 0, 0, 0, 0, 0,
     32, 0, 3, 0, 0,
     6004, 0, 0, 6004, 153,
     0, 12);
