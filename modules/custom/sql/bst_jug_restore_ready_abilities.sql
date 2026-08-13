-- =====================================================================
-- bst_jug_restore_ready_abilities.sql
-- Re-add jug Ready ability IDs stripped by older fix_dangling_mob_skills runs,
-- and fix Zealous Snort targeting (was enemy; must be self for master buff).
--
-- mob_skill_lists must contain pet_skills.mob_skill_id, NOT pet_skill_id.
-- Keeping both namespaces in this table made manual Ready and auto-Ready
-- execute different scripts for the same jug.
-- Apply after the base pet/mob skill tables. Idempotent.
-- =====================================================================

-- Normalize every existing Jug_* family in one pass. The base table stores
-- Ready-menu IDs; runtime mob lists require the mapped executable skill IDs.
INSERT IGNORE INTO `mob_skill_lists` (`skill_list_name`, `skill_list_id`, `mob_skill_id`)
SELECT m.`skill_list_name`, m.`skill_list_id`, p.`mob_skill_id`
FROM `mob_skill_lists` AS m
JOIN `pet_skills` AS p ON p.`pet_skill_id` = m.`mob_skill_id`
WHERE m.`skill_list_name` LIKE 'Jug\_%' AND p.`mob_skill_id` <> p.`pet_skill_id`;

DELETE m
FROM `mob_skill_lists` AS m
JOIN `pet_skills` AS p ON p.`pet_skill_id` = m.`mob_skill_id`
WHERE m.`skill_list_name` LIKE 'Jug\_%' AND p.`mob_skill_id` <> p.`pet_skill_id`;

-- Chapuli (Bertha)
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 757 AND `mob_skill_id` IN (761, 762, 2946, 2947);
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Chapuli',757,3927); -- Sensilla Blades
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Chapuli',757,3928); -- Tegmina Buffet

-- Raaz (Vickie)
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 759 AND `mob_skill_id` IN (765, 766);
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Raaz',759,3931); -- Sweeping Gouge
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Raaz',759,3932); -- Zealous Snort

-- Lynx (Gaston) — Charged Whisker
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 765 AND `mob_skill_id` = 746;
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Lynx',765,3912);

-- Apkallu (Iyo)
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 755 AND `mob_skill_id` IN (756, 757);
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Apkallu',755,3922); -- Wing Slap
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Apkallu',755,3923); -- Beak Lunge

-- Acuex (Bredo)
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 762 AND `mob_skill_id` IN (774, 775);
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Acuex',762,3939); -- Foul Waters
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Acuex',762,3940); -- Pestilent Plume

-- Spider (Hachirobe)
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 764 AND `mob_skill_id` IN (777, 778, 779);
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Spider',764,3942); -- Sickle Slash
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Spider',764,3943); -- Acid Spray
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Spider',764,3944); -- Spider Web

-- Antlion (Annabelle)
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 743 AND `mob_skill_id` IN (714, 715, 716, 717);
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Antlion',743,3882); -- Sandblast
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Antlion',743,3883); -- Sandpit
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Antlion',743,3884); -- Venom Spray
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Antlion',743,3885); -- Mandibular Bite

-- Slime (Patrice)
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 2093 AND `mob_skill_id` IN (792, 793, 794);
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Slime',2093,3956);
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Slime',2093,3957);
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Slime',2093,3958);

-- Crab Hi (Edwin)
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 2094 AND `mob_skill_id` IN (788, 789);
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_CrabHi',2094,3952);
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_CrabHi',2094,3953);

-- Lucani (Angelina)
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 2095 AND `mob_skill_id` IN (786, 787);
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Lucani',2095,3950);
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Lucani',2095,3951);

-- Mosquito (Yoko)
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 2096 AND `mob_skill_id` IN (781, 782);
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Mosquito',2096,3945);
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Mosquito',2096,3946);

-- Beetle Hi (Sefina) — Rhinowrecker + kit
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 2097 AND `mob_skill_id` IN (707, 708, 709, 710, 711, 791);
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_BeetleHi',2097,3875);
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_BeetleHi',2097,3876);
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_BeetleHi',2097,3877);
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_BeetleHi',2097,3878);
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_BeetleHi',2097,3879);
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_BeetleHi',2097,3955);

-- Toad (Brave Hero Glenn) shipped with skill_list_id=0.
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 2098;
INSERT INTO `mob_skill_lists` VALUES
('Jug_Toad',2098,3868), -- Frogkick
('Jug_Toad',2098,3926); -- Water Wall
UPDATE `mob_pools` SET `skill_list_id` = 2098 WHERE `poolid` = 7548;

-- Zealous Snort: self/master buff, not enemy target.
UPDATE `pet_skills`
SET `pet_valid_targets` = 3
WHERE `pet_skill_id` = 766 AND `pet_skill_name` = 'zealous_snort';
