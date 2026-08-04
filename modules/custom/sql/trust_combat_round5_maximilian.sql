-- Maximilian: restore sword DW kit (was remapped to dagger WS).
-- Fast Blade / Vorpal Blade / Swift Blade. THF/NIN Sword.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1090;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Maximilian',1090,32), -- Fast Blade
('TRUST_Maximilian',1090,40), -- Vorpal Blade
('TRUST_Maximilian',1090,41); -- Swift Blade

-- Affirm standard sword WS anims / SC props.
UPDATE `mob_skills` SET
    `mob_anim_id` = 1,
    `mob_skill_name` = 'fast_blade',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 4,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 32;

UPDATE `mob_skills` SET
    `mob_anim_id` = 9,
    `mob_skill_name` = 'vorpal_blade',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 5,
    `secondary_sc` = 8,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 40;

UPDATE `mob_skills` SET
    `mob_anim_id` = 10,
    `mob_skill_name` = 'swift_blade',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 9,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 41;

-- THF/NIN, Sword, delay 240.
UPDATE `mob_pools` SET
    `mJob` = 6,
    `sJob` = 13,
    `cmbSkill` = 3,
    `cmbDelay` = 240
WHERE `poolid` = 5975;
