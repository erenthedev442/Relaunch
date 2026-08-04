-- =====================================================================
-- trust_maat_uc.sql
-- Maat UC (spell 1006 / pool 6006): MNK/WAR H2H, Hollow Smite only.
-- Prefer trust_combat_round5_maat_uc.sql.
-- =====================================================================

DELETE FROM `mob_skill_lists` WHERE skill_list_id = 1121;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Maat_UC', 1121, 3496); -- Hollow Smite

UPDATE `mob_pools`
SET
    `mJob` = 2,
    `sJob` = 1,
    `cmbSkill` = 1,
    `cmbDelay` = 240,
    `spellList` = 0,
    `skill_list_id` = 0
WHERE `poolid` = 6006;
