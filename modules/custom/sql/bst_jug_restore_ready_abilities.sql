-- =====================================================================
-- bst_jug_restore_ready_abilities.sql
-- Re-add jug Ready ability IDs stripped by older fix_dangling_mob_skills runs,
-- and fix Zealous Snort targeting (was enemy; must be self for master buff).
--
-- Ability IDs live in pet_skills.pet_skill_id and drive the Ready menu.
-- Real mobskill IDs from jugpet_ready_moves.sql remain for auto-ready.
-- Apply AFTER fix_dangling_mob_skills.sql. Idempotent INSERT IGNORE.
-- =====================================================================

-- Chapuli (Bertha)
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Chapuli',757,761); -- Sensilla Blades
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Chapuli',757,762); -- Tegmina Buffet

-- Raaz (Vickie)
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Raaz',759,765); -- Sweeping Gouge
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Raaz',759,766); -- Zealous Snort

-- Lynx (Gaston) — Charged Whisker
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Lynx',765,746);

-- Apkallu (Iyo)
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Apkallu',755,756); -- Wing Slap
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Apkallu',755,757); -- Beak Lunge

-- Acuex (Bredo)
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Acuex',762,774); -- Foul Waters
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Acuex',762,775); -- Pestilent Plume

-- Spider (Hachirobe)
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Spider',764,777); -- Sickle Slash
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Spider',764,778); -- Acid Spray
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Spider',764,779); -- Spider Web

-- Antlion (Annabelle)
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Antlion',743,714); -- Sandblast
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Antlion',743,715); -- Sandpit
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Antlion',743,716); -- Venom Spray
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Antlion',743,717); -- Mandibular Bite

-- Slime (Patrice)
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Slime',2093,792);
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Slime',2093,793);
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Slime',2093,794);

-- Crab Hi (Edwin)
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_CrabHi',2094,788);
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_CrabHi',2094,789);

-- Lucani (Angelina)
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Lucani',2095,786);
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Lucani',2095,787);

-- Mosquito (Yoko)
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Mosquito',2096,781);
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_Mosquito',2096,782);

-- Beetle Hi (Sefina) — Rhinowrecker + kit
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_BeetleHi',2097,707);
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_BeetleHi',2097,708);
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_BeetleHi',2097,709);
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_BeetleHi',2097,710);
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_BeetleHi',2097,711);
INSERT IGNORE INTO `mob_skill_lists` VALUES ('Jug_BeetleHi',2097,791);

-- Zealous Snort: self/master buff, not enemy target.
UPDATE `pet_skills`
SET `pet_valid_targets` = 3
WHERE `pet_skill_id` = 766 AND `pet_skill_name` = 'zealous_snort';
