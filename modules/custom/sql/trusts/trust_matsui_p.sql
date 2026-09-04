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
--   Spell / packet stay Exc_S (1004 / Excenmille_S). Look is retail Matsui
--   model 3121 (0x0000310C, same encoding as Cornelia 3119 / Monberaux 3120).
--   That mesh lives in year-round ROM/310/13.DAT (shipped in Custom DATs).
--   Kit is his retail NIN/BLM year-round moves — no campaign-only skills.
--
-- NAMETAG
--   packet_name stays Excenmille_S so the first spawn packet uses a DAT the
--   client has. Lua then renameEntity('matsui-p') — same overlay Meat/Gemma
--   use. Do NOT send the retail string 'Matsui-P': that is spell 1003's
--   campaign DAT key and R0s the client on the 0x67 trust-name packet.
--
-- APPLYING
--   1) Apply this file (deploy recurses modules/custom/sql/**/*.sql)
--   2) RESTART THE MAP SERVER (LoadTrustList / LoadMobSpellList are boot-only)
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
-- SPELL LIST ID IS 4004, NOT 6004 -- deliberate, do not "tidy" it back.
--   LoadMobSpellList() reads `WHERE spell_list_id < MAX_MOBSPELLLIST_ID`. That bound was
--   5000, so list 6004 never loaded, m_SpellListContainer stayed null, and the first
--   MA/SPECIFIC gambit in matsui_p.lua dereferenced it -> map ACCESS_VIOLATION every time
--   a player summoned Matsui-P (crash 2026-09-01 06:56:29, spell.cpp:828). The bound is
--   now 65535 and the deref is guarded, but 4004 keeps this trust working on any binary,
--   including one built before that change. Skill lists have no such bound, so the
--   mob_skill_lists id below stays 6004.
DELETE FROM mob_spell_lists WHERE spell_list_id IN (4004, 6004);
INSERT INTO mob_spell_lists
    (spell_list_name, spell_list_id, spell_id, min_level, max_level)
VALUES
    -- Elemental ninjutsu Ichi / Ni / San (year-round). Retail MBs San then T1.
    ('matsui_p', 4004, 320,  15, 255), -- katon_ichi
    ('matsui_p', 4004, 321,  40, 255), -- katon_ni
    ('matsui_p', 4004, 322,  73, 255), -- katon_san
    ('matsui_p', 4004, 323,  15, 255), -- hyoton_ichi
    ('matsui_p', 4004, 324,  40, 255), -- hyoton_ni
    ('matsui_p', 4004, 325,  73, 255), -- hyoton_san
    ('matsui_p', 4004, 326,  15, 255), -- huton_ichi
    ('matsui_p', 4004, 327,  40, 255), -- huton_ni
    ('matsui_p', 4004, 328,  73, 255), -- huton_san
    ('matsui_p', 4004, 329,  15, 255), -- doton_ichi
    ('matsui_p', 4004, 330,  40, 255), -- doton_ni
    ('matsui_p', 4004, 331,  73, 255), -- doton_san
    ('matsui_p', 4004, 332,  15, 255), -- raiton_ichi
    ('matsui_p', 4004, 333,  40, 255), -- raiton_ni
    ('matsui_p', 4004, 334,  73, 255), -- raiton_san
    ('matsui_p', 4004, 335,  15, 255), -- suiton_ichi
    ('matsui_p', 4004, 336,  40, 255), -- suiton_ni
    ('matsui_p', 4004, 337,  73, 255), -- suiton_san
    ('matsui_p', 4004, 338,  12, 255), -- utsusemi_ichi
    ('matsui_p', 4004, 339,  37, 255), -- utsusemi_ni
    ('matsui_p', 4004, 340,  73, 255), -- utsusemi_san
    ('matsui_p', 4004, 319,  78, 255), -- aisha_ichi
    ('matsui_p', 4004, 507,  85, 255), -- myoshu_ichi
    ('matsui_p', 4004, 508,  83, 255), -- yurin_ichi
    ('matsui_p', 4004, 509,  93, 255), -- kakka_ichi
    ('matsui_p', 4004, 510,  88, 255), -- migawari_ichi
    -- T1 elemental nukes + Burn / Aspir / Stun (year-round BLM sub).
    ('matsui_p', 4004, 144,  12, 255), -- fire
    ('matsui_p', 4004, 149,  12, 255), -- blizzard
    ('matsui_p', 4004, 154,  12, 255), -- aero
    ('matsui_p', 4004, 159,  12, 255), -- stone
    ('matsui_p', 4004, 164,  12, 255), -- thunder
    ('matsui_p', 4004, 169,  12, 255), -- water
    ('matsui_p', 4004, 235,  24, 255), -- burn
    ('matsui_p', 4004, 247,  25, 255), -- aspir
    ('matsui_p', 4004, 248,  83, 255), -- aspir_ii
    ('matsui_p', 4004, 252,  37, 255); -- stun

DELETE FROM mob_skill_lists WHERE skill_list_id = 6004;
INSERT INTO mob_skill_lists (skill_list_name, skill_list_id, mob_skill_id)
VALUES
    ('matsui_p', 6004, 137), -- Blade: Metsu (Darkness / Fragmentation)
    ('matsui_p', 6004, 138), -- Blade: Kamu  (Fragmentation / Compression)
    ('matsui_p', 6004, 140), -- Blade: Hi    (Darkness / Gravitation)
    ('matsui_p', 6004, 141); -- Blade: Shun  (Fusion / Impaction)

-- ---- 3. Pool 6004 = Matsui-P (model 3121 + NIN/BLM) -------------------
REPLACE INTO mob_pools
    (poolid, name,       packet_name, speciesid, modelid,
     mJob, sJob, cmbSkill, cmbDelay, cmbDmgMult,
     behavior, aggro, true_detection, links, mobType, immunity,
     name_prefix, flag, entityFlags, animationsub, hasSpellScript,
     spellList, namevis, roamflag, skill_list_id, resist_id,
     modelSize, modelHitboxSize)
VALUES
    -- Look 0x0000310C = model 3121 (Matsui-P). packet_name MUST stay
    -- Excenmille_S so the spawn/0x67 DAT key is safe. Nametag is Lua overlay.
    (6004, 'matsui_p', 'Excenmille_S', 297, UNHEX('0000310C00000000000000000000000000000000'),
     13, 4, 9, 195, 300,
     0, 0, 0, 0, 0, 0,
     32, 0, 3, 0, 0,
     4004, 0, 0, 6004, 153,
     0, 12);
