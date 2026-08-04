-- Sylvie UC: GEO/WHM S-tier Indi buffer. Nott via Lua; no auto TP list.
-- Add Indi-Focus / Indi-Languor to spell kit.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1096;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Sylvie_UC',1096,3502); -- Nott (50)

UPDATE `mob_skills` SET
    `mob_anim_id` = 89,
    `mob_skill_name` = 'nott',
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 1
WHERE `mob_skill_id` = 3502;

-- Ensure Focus / Languor are on her list (C++ Indi selectors need them).
INSERT IGNORE INTO `mob_spell_lists` VALUES ('TRUST_Sylvie_UC',394,785,62,255); -- indi-focus
INSERT IGNORE INTO `mob_spell_lists` VALUES ('TRUST_Sylvie_UC',394,794,88,255); -- indi-languor

UPDATE `mob_pools` SET
    `mJob` = 21,
    `sJob` = 3,
    `cmbSkill` = 11,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `skill_list_id` = 0,
    `spellList` = 394
WHERE `poolid` = 5981;
