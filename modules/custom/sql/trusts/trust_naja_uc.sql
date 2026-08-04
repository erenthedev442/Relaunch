-- =====================================================================
-- trust_naja_uc.sql
-- Naja Salaheem UC (spell 1008 / pool 6008): MNK/WAR club OPENER.
-- Prefer trust_combat_round5_naja_uc.sql.
-- =====================================================================

DELETE FROM `mob_skill_lists` WHERE skill_list_id = 1123;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Naja_Salaheem_UC', 1123, 3215); -- Peacebreaker
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Naja_Salaheem_UC', 1123, 168);  -- Hexa Strike
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Naja_Salaheem_UC', 1123, 3502); -- Nott
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Naja_Salaheem_UC', 1123, 169);  -- Black Halo
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Naja_Salaheem_UC', 1123, 3503); -- Justicebreaker

UPDATE `mob_pools`
SET
    `mJob` = 2,
    `sJob` = 1,
    `cmbSkill` = 11,
    `cmbDelay` = 240,
    `spellList` = 0,
    `skill_list_id` = 0
WHERE `poolid` = 6008;
