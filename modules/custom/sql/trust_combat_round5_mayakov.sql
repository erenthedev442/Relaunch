-- Mayakov: restore Coming Up Roses + sword kit (was Savage Blade placeholder).
-- Anim 420. DNC/WAR Sword.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1081;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Mayakov',1081,32),   -- Fast Blade
('TRUST_Mayakov',1081,40),   -- Vorpal Blade
('TRUST_Mayakov',1081,41),   -- Swift Blade
('TRUST_Mayakov',1081,3454); -- Coming Up Roses (Light/Fusion)

UPDATE `mob_skills` SET
    `mob_anim_id` = 420,
    `mob_skill_name` = 'coming_up_roses',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `knockback` = 0,
    `primary_sc` = 13,
    `secondary_sc` = 11,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3454;

-- DNC/WAR, Sword.
UPDATE `mob_pools` SET
    `mJob` = 19,
    `sJob` = 1,
    `cmbSkill` = 3,
    `cmbDelay` = 240
WHERE `poolid` = 5966;
