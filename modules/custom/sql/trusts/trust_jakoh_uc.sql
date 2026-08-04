-- =====================================================================
-- trust_jakoh_uc.sql
-- Jakoh Wahcondalo UC (spell 956 / pool 5956): THF/WAR knife skirmisher.
-- Prefer trust_combat_round5_jakoh_uc.sql (includes Sarva's Storm).
-- =====================================================================

DELETE FROM `mob_skill_lists` WHERE skill_list_id = 1071;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Jakoh_Wahcondalo_UC', 1071, 23);   -- Dancing Edge
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Jakoh_Wahcondalo_UC', 1071, 25);   -- Evisceration
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Jakoh_Wahcondalo_UC', 1071, 3497); -- Sarva's Storm

UPDATE `mob_pools`
SET
    `mJob` = 6,
    `sJob` = 1,
    `cmbSkill` = 2,
    `cmbDelay` = 201,
    `spellList` = 0,
    `skill_list_id` = 0
WHERE `poolid` = 5956;
