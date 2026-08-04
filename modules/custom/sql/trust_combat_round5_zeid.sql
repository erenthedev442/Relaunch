-- Zeid: restore retail GS kit (base had Hard Slash…Scourge; missing Abyssal*).
-- DRK/DRK. Freezebite / Ground Strike / Abyssal Drain / Abyssal Strike.
-- Spell list: Absorb-* (incl. Attri), Endark, Drain/Aspir, Stun.
-- A weaponskill path; ASAP@1000; AI in zeid.lua.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1021;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Zeid',1021,980),  -- Freezebite (Zeid anim)
('TRUST_Zeid',1021,981),  -- Ground Strike (Zeid anim)
('TRUST_Zeid',1021,982),  -- Abyssal Drain
('TRUST_Zeid',1021,983);  -- Abyssal Strike

-- Affirm Zeid GS / unique WS anims + SC (Abyssal* have none).
UPDATE `mob_skills` SET
    `mob_anim_id` = 683,
    `mob_skill_name` = 'freezebite',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `mob_prepare_time` = 500,
    `primary_sc` = 7,
    `secondary_sc` = 6,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 980;

UPDATE `mob_skills` SET
    `mob_anim_id` = 684,
    `mob_skill_name` = 'ground_strike',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `mob_prepare_time` = 500,
    `primary_sc` = 12,
    `secondary_sc` = 10,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 981;

UPDATE `mob_skills` SET
    `mob_anim_id` = 671,
    `mob_skill_name` = 'abyssal_drain',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `mob_prepare_time` = 500,
    `primary_sc` = 0,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 982;

UPDATE `mob_skills` SET
    `mob_anim_id` = 672,
    `mob_skill_name` = 'abyssal_strike',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `mob_prepare_time` = 500,
    `primary_sc` = 0,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 983;

-- Keep Trust duplicate rows aligned (list uses 982/983).
UPDATE `mob_skills` SET
    `mob_anim_id` = 671,
    `mob_skill_name` = 'abyssal_drain',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `mob_prepare_time` = 1500,
    `primary_sc` = 0,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3195;

UPDATE `mob_skills` SET
    `mob_anim_id` = 672,
    `mob_skill_name` = 'abyssal_strike',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `mob_prepare_time` = 1500,
    `primary_sc` = 0,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3196;

-- Spell list 318: add Absorb-Attri + Endark (retail kit).
DELETE FROM `mob_spell_lists` WHERE `spell_list_id` = 318;

INSERT INTO `mob_spell_lists` VALUES
('TRUST_Zeid',318,242,61,255),  -- absorb-acc
('TRUST_Zeid',318,243,91,255),  -- absorb-attri
('TRUST_Zeid',318,245,10,255),  -- drain
('TRUST_Zeid',318,246,62,255),  -- drain_ii
('TRUST_Zeid',318,247,20,255),  -- aspir
('TRUST_Zeid',318,248,78,255),  -- aspir_ii
('TRUST_Zeid',318,252,37,255),  -- stun
('TRUST_Zeid',318,266,43,255),  -- absorb-str
('TRUST_Zeid',318,267,41,255),  -- absorb-dex
('TRUST_Zeid',318,268,35,255),  -- absorb-vit
('TRUST_Zeid',318,269,37,255),  -- absorb-agi
('TRUST_Zeid',318,270,39,255),  -- absorb-int
('TRUST_Zeid',318,271,31,255),  -- absorb-mnd
('TRUST_Zeid',318,272,33,255),  -- absorb-chr
('TRUST_Zeid',318,275,45,255),  -- absorb-tp
('TRUST_Zeid',318,311,85,255);  -- endark

-- DRK/DRK, Great Sword.
UPDATE `mob_pools` SET
    `mJob` = 8,
    `sJob` = 8,
    `cmbSkill` = 4,
    `cmbDelay` = 240,
    `skill_list_id` = 1021,
    `spellList` = 318
WHERE `poolid` = 5906;
