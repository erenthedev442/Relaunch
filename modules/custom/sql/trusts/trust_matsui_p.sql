-- =====================================================================
-- trust_matsui_p.sql  --  Trust: Matsui-P (Void Keeper capstone)
--
-- REPURPOSES retail Excenmille (S) slot: spell 1004 / pool 6004.
-- Same technique as Corvus→Curilla (902), Meat→Excenmille (899),
-- Gemma→Nanaa (901).
--
-- WHY NOT 1003
--   Client spell ID 1003 is the seasonal Cornelia/Matsui campaign slot.
--   Casting it R0-crashes outside campaign DAT windows — look/job overrides
--   do not help because the client loads the spell-ID asset first.
--
-- WHY 1004
--   Excenmille (S) is a permanent year-round alter ego in the client DAT.
--   Menu label stays "Excenmille (S)"; Void Keeper binds spell 1004 and
--   casting it summons Matsui-P (model 3121 + NIN/BLM kit). Spell-ID DAT
--   is Exc_S (safe); server look/packet override the entity appearance.
--   Stock Exc is already Meat on 899; Exc_S is not a farmable trust.
--
-- APPLYING
--   1) sudo mariadb xidb < modules/custom/sql/trusts/trust_matsui_p.sql
--   2) RESTART THE MAP SERVER (LoadTrustList runs only at boot).
-- =====================================================================

-- ---- 1. Overwrite spell slot 1004 (Excenmille_S -> Matsui-P) ----------
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

-- Kill the cursed seasonal slot so it cannot be cast / learned.
DELETE FROM spell_list WHERE spellid = 1003;
DELETE FROM mob_pools WHERE poolid = 6003;
DELETE FROM mob_spell_lists WHERE spell_list_id = 6003;
DELETE FROM mob_skill_lists WHERE skill_list_id = 6003;

-- Clear prior wrong slots if previously applied as 1021/6021.
DELETE FROM spell_list WHERE spellid = 1021 AND name = 'matsui_p';
DELETE FROM mob_pools WHERE poolid = 6021 AND name = 'matsui_p';
DELETE FROM mob_spell_lists WHERE spell_list_id = 6021;
DELETE FROM mob_skill_lists WHERE skill_list_id = 6021;

-- Migrate learned spells carefully:
--   * Old Matsui (1003) / TrustEarned_1003 -> keep as 1004 + TrustEarned_1004
--   * Prior Exc_S-only owners lose 1004 (slot is now Void Keeper Matsui;
--     they must buy from Void Keeper — do NOT convert farmed Exc_S).
CREATE TEMPORARY TABLE IF NOT EXISTS _matsui_owners AS
    SELECT DISTINCT charid FROM char_spells WHERE spellid = 1003
    UNION
    SELECT DISTINCT charid FROM char_vars
        WHERE varname = 'TrustEarned_1003' AND value = 1;
DELETE FROM char_spells WHERE spellid IN (1003, 1004);
INSERT IGNORE INTO char_spells (charid, spellid)
    SELECT charid, 1004 FROM _matsui_owners;
-- Drop farmed Exc_S earned flags; re-stamp only real Matsui owners.
DELETE FROM char_vars WHERE varname IN ('TrustEarned_1003', 'TrustEarned_1004');
INSERT INTO char_vars (charid, varname, value, expiry)
    SELECT charid, 'TrustEarned_1004', 1, 0 FROM _matsui_owners;
DROP TEMPORARY TABLE IF EXISTS _matsui_owners;

-- ---- 2. Spell / WS lists on pool 6004 (= 1004 + 5000) ----------------
DELETE FROM mob_spell_lists WHERE spell_list_id = 6004;
INSERT INTO mob_spell_lists
    (spell_list_name, spell_list_id, spell_id, min_level, max_level)
VALUES
    -- Utsusemi
    ('matsui_p', 6004, 338,   1, 255), -- utsusemi_ichi
    ('matsui_p', 6004, 339,  37, 255), -- utsusemi_ni
    ('matsui_p', 6004, 340,  99, 255), -- utsusemi_san
    -- Elemental Ninjutsu San (MB)
    ('matsui_p', 6004, 322,  90, 255), -- katon_san
    ('matsui_p', 6004, 325,  90, 255), -- hyoton_san
    ('matsui_p', 6004, 328,  90, 255), -- huton_san
    ('matsui_p', 6004, 331,  90, 255), -- doton_san
    ('matsui_p', 6004, 334,  90, 255), -- raiton_san
    ('matsui_p', 6004, 337,  90, 255), -- suiton_san
    -- Single-target elemental nukes I
    ('matsui_p', 6004, 144,   1, 255), -- fire
    ('matsui_p', 6004, 149,   1, 255), -- blizzard
    ('matsui_p', 6004, 154,   1, 255), -- aero
    ('matsui_p', 6004, 159,   1, 255), -- stone
    ('matsui_p', 6004, 164,   1, 255), -- thunder
    ('matsui_p', 6004, 169,   1, 255), -- water
    -- Utility
    ('matsui_p', 6004, 235,  24, 255), -- burn
    ('matsui_p', 6004, 247,  25, 255), -- aspir
    ('matsui_p', 6004, 252,  45, 255), -- stun
    ('matsui_p', 6004, 319,  60, 255), -- aisha_ichi
    ('matsui_p', 6004, 507,  60, 255), -- myoshu_ichi
    ('matsui_p', 6004, 508,  60, 255), -- yurin_ichi
    ('matsui_p', 6004, 509,  60, 255), -- kakka_ichi
    ('matsui_p', 6004, 510,  88, 255); -- migawari_ichi

DELETE FROM mob_skill_lists WHERE skill_list_id = 6004;
INSERT INTO mob_skill_lists (skill_list_name, skill_list_id, mob_skill_id)
VALUES
    ('matsui_p', 6004, 128), -- Blade: Rin
    ('matsui_p', 6004, 129), -- Blade: Retsu
    ('matsui_p', 6004, 133), -- Blade: Ei
    ('matsui_p', 6004, 134), -- Blade: Jin
    ('matsui_p', 6004, 135), -- Blade: Ten
    ('matsui_p', 6004, 136), -- Blade: Ku
    ('matsui_p', 6004, 138), -- Blade: Kamu
    ('matsui_p', 6004, 140), -- Blade: Hi
    ('matsui_p', 6004, 141); -- Blade: Shun

-- ---- 3. Overwrite mob pool 6004 with Matsui-P ------------------------
--   Look 0x0000310C = model 3121 (trust-era size=0, same encoding as
--   Cornelia 0x00002F0C / Monberaux 0x0000300C). NIN/BLM + katana.
REPLACE INTO mob_pools
    (poolid, name,       packet_name, speciesid, modelid,
     mJob, sJob, cmbSkill, cmbDelay, cmbDmgMult,
     behavior, aggro, true_detection, links, mobType, immunity,
     name_prefix, flag, entityFlags, animationsub, hasSpellScript,
     spellList, namevis, roamflag, skill_list_id, resist_id,
     modelSize, modelHitboxSize)
VALUES
    (6004, 'matsui_p', 'Matsui-P', 297, UNHEX('0000310C00000000000000000000000000000000'),
     13, 4, 9, 210, 300,
     0, 0, 0, 0, 0, 0,
     32, 0, 3, 0, 0,
     6004, 0, 0, 6004, 153,
     2, 11);
