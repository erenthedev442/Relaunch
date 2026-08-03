-- ============================================================================
-- trust_combat_audit_fix.sql
--
-- Full-roster hotfixes for broken trust WS / pools:
--   1) Morimar / Darrcuiln — custom MS had no Lua (0 dmg) → player axe/GA WS
--   2) Lilisette / II — DNC MS had no Lua → player dagger WS
--   3) Strip orphan signature MS (Mayakov / Romaa / Zazarg / Ovjang)
--   4) Pool cmbSkill fixes (Makki Archery, Lhe H2H, Morimar Axe, Darrcuiln GA)
--
-- Safe to re-apply. Map restart required.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Morimar / Darrcuiln
-- ---------------------------------------------------------------------------
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1105;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Morimar',1105,69);  -- Rampage
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Morimar',1105,70);  -- Calamity
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Morimar',1105,72);  -- Decimation
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Morimar',1105,76);  -- Cloudsplitter
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Morimar',1105,77);  -- Ruinator

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1106;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Darrcuiln',1106,86); -- Raging Rush
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Darrcuiln',1106,88); -- Steel Cyclone
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Darrcuiln',1106,91); -- Fell Cleave
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Darrcuiln',1106,92); -- Ukko's Fury

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 491;
INSERT INTO `mob_skill_lists` VALUES ('Morimar',491,69);
INSERT INTO `mob_skill_lists` VALUES ('Morimar',491,70);
INSERT INTO `mob_skill_lists` VALUES ('Morimar',491,72);
INSERT INTO `mob_skill_lists` VALUES ('Morimar',491,76);
INSERT INTO `mob_skill_lists` VALUES ('Morimar',491,77);

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 489;
INSERT INTO `mob_skill_lists` VALUES ('Darrcuiln',489,86);
INSERT INTO `mob_skill_lists` VALUES ('Darrcuiln',489,88);
INSERT INTO `mob_skill_lists` VALUES ('Darrcuiln',489,91);
INSERT INTO `mob_skill_lists` VALUES ('Darrcuiln',489,92);

-- ---------------------------------------------------------------------------
-- Lilisette / Lilisette II — dagger WS (custom DNC MS had no Lua)
-- ---------------------------------------------------------------------------
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1060;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Lilisette',1060,16);  -- Wasp Sting
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Lilisette',1060,23);  -- Dancing Edge
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Lilisette',1060,29);  -- Pyrrhic Kleos
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Lilisette',1060,31);  -- Rudra's Storm
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Lilisette',1060,224); -- Exenterator

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1128;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Lilisette_II',1128,16);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Lilisette_II',1128,23);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Lilisette_II',1128,29);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Lilisette_II',1128,31);
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Lilisette_II',1128,224);

-- ---------------------------------------------------------------------------
-- Strip orphan signature moves (no Lua → 0 damage if selected as HIGHEST)
-- ---------------------------------------------------------------------------
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1081 AND `mob_skill_id` = 3454; -- Mayakov Coming Up Roses
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1064 AND `mob_skill_id` = 3297; -- Romaa Cobra Clamp
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1039 AND `mob_skill_id` = 3240; -- Zazarg Meteoric Impact
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1040 AND `mob_skill_id` = 3244; -- Ovjang Sixth Element

-- ---------------------------------------------------------------------------
-- Pool combat skill fixes
-- ---------------------------------------------------------------------------
UPDATE `mob_pools` SET `cmbSkill` = 25, `cmbDelay` = 500, `cmbDmgMult` = 200 WHERE `poolid` = 5988; -- Makki Archery
UPDATE `mob_pools` SET `cmbSkill` = 1 WHERE `poolid` = 5964;  -- Lhe H2H
UPDATE `mob_pools` SET `cmbSkill` = 2 WHERE `poolid` = 5990;  -- Morimar Axe
UPDATE `mob_pools` SET `cmbSkill` = 6 WHERE `poolid` = 5991;  -- Darrcuiln Great Axe
