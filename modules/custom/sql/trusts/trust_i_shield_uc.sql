-- =====================================================================
-- trust_i_shield_uc.sql
-- Invincible Shield UC (spell 954 / pool 5954): WAR/COR provoke DD.
-- Prefer trust_combat_round5_i_shield_uc.sql (includes Soturi's Fury).
-- =====================================================================

DELETE FROM `mob_skill_lists` WHERE skill_list_id = 1069;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Invincible_Shield_UC', 1069, 86);   -- Raging Rush
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Invincible_Shield_UC', 1069, 88);   -- Steel Cyclone
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Invincible_Shield_UC', 1069, 3499); -- Soturi's Fury

UPDATE `mob_pools`
SET
    `mJob` = 1,
    `sJob` = 17,
    `cmbSkill` = 6,
    `spellList` = 0,
    `skill_list_id` = 1069
WHERE `poolid` = 5954;
