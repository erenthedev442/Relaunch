-- Prishe: restore unique Trust H2H WS (was remapped to player MNK WS).
-- MNK/WHM. Knuckle Sandwich / Nullifying Dropkick / Auroral Uppercut.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1028;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Prishe',1028,3234), -- Nullifying Dropkick
('TRUST_Prishe',1028,3235), -- Auroral Uppercut
('TRUST_Prishe',1028,3236); -- Knuckle Sandwich

UPDATE `mob_skills` SET
    `mob_anim_id` = 1095,
    `mob_skill_name` = 'nullifying_dropkick',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 7,
    `secondary_sc` = 6,
    `tertiary_sc` = 8
WHERE `mob_skill_id` = 3234;

UPDATE `mob_skills` SET
    `mob_anim_id` = 1343,
    `mob_skill_name` = 'auroral_uppercut',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 13,
    `secondary_sc` = 12,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3235;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2033,
    `mob_skill_name` = 'knuckle_sandwich',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 11,
    `secondary_sc` = 2,
    `tertiary_sc` = 8
WHERE `mob_skill_id` = 3236;

-- MNK/WHM, Hand-to-Hand.
UPDATE `mob_pools` SET
    `mJob` = 2,
    `sJob` = 3,
    `cmbSkill` = 1,
    `cmbDelay` = 240
WHERE `poolid` = 5913;
