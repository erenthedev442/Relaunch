-- Klara: restore Fast/Vorpal/Savage + Temblor Blade (was Red Lotus/Spirits Within).
-- WAR/WAR Sword.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1063;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Klara',1063,32),   -- Fast Blade
('TRUST_Klara',1063,40),   -- Vorpal Blade
('TRUST_Klara',1063,42),   -- Savage Blade
('TRUST_Klara',1063,3296); -- Temblor Blade (AoE)

UPDATE `mob_skills` SET
    `mob_anim_id` = 259,
    `mob_skill_name` = 'temblor_blade',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 5.0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 5,
    `secondary_sc` = 8
WHERE `mob_skill_id` = 3296;

-- WAR/WAR, Sword.
UPDATE `mob_pools` SET
    `mJob` = 1,
    `sJob` = 1,
    `cmbSkill` = 3
WHERE `poolid` = 5948;
