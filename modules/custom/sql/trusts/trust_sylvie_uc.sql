-- =====================================================================
-- trust_sylvie_uc.sql
-- Sylvie UC (spell 981 / pool 5981): GEO/WHM Indi buffer.
-- Prefer trust_combat_round5_sylvie_uc.sql.
-- =====================================================================

DELETE FROM `mob_skill_lists` WHERE skill_list_id = 1096;
INSERT INTO `mob_skill_lists` VALUES ('TRUST_Sylvie_UC', 1096, 3502); -- Nott

INSERT IGNORE INTO `mob_spell_lists` VALUES ('TRUST_Sylvie_UC',394,785,62,255); -- indi-focus
INSERT IGNORE INTO `mob_spell_lists` VALUES ('TRUST_Sylvie_UC',394,794,88,255); -- indi-languor

UPDATE `mob_pools`
SET
    `mJob` = 21,
    `sJob` = 3,
    `cmbSkill` = 11,
    `spellList` = 394,
    `skill_list_id` = 0
WHERE `poolid` = 5981;
