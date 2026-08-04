-- =====================================================================
-- trust_pieuje_uc.sql
-- Pieuje UC (spell 953 / pool 5953): WHM/PLD stationary club healer.
-- Prefer trust_combat_round5_pieuje_uc.sql.
-- =====================================================================

DELETE FROM `mob_skill_lists` WHERE skill_list_id = 1068;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Pieuje_UC', 1068, 163);  -- Starlight
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Pieuje_UC', 1068, 164);  -- Moonlight
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Pieuje_UC', 1068, 3502); -- Nott

UPDATE `mob_pools`
SET
    `mJob` = 3,
    `sJob` = 7,
    `cmbSkill` = 11,
    `cmbDelay` = 240,
    `spellList` = 365,
    `skill_list_id` = 0
WHERE `poolid` = 5953;
