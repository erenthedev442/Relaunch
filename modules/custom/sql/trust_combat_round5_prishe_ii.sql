-- Prishe II: restore unique Trust H2H WS + anima (was remapped to player MNK WS).
-- WHM/MNK. Knuckle Sandwich / Nullifying Dropkick / Auroral Uppercut.
-- Psychoanima (3540) / Hysteroanima (3539).

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1126;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Prishe_II',1126,3234), -- Nullifying Dropkick
('TRUST_Prishe_II',1126,3235), -- Auroral Uppercut
('TRUST_Prishe_II',1126,3236), -- Knuckle Sandwich
('TRUST_Prishe_II',1126,3539), -- Hysteroanima (magic immunity)
('TRUST_Prishe_II',1126,3540); -- Psychoanima (physical immunity)

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

UPDATE `mob_skills` SET
    `mob_anim_id` = 1093,
    `mob_skill_name` = 'hysteroanima',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 1
WHERE `mob_skill_id` = 3539;

UPDATE `mob_skills` SET
    `mob_anim_id` = 1094,
    `mob_skill_name` = 'psychoanima',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 1
WHERE `mob_skill_id` = 3540;

-- WHM/MNK, Hand-to-Hand (melee-fighter pace; was delay 480).
UPDATE `mob_pools` SET
    `mJob` = 3,
    `sJob` = 2,
    `cmbSkill` = 1,
    `cmbDelay` = 240
WHERE `poolid` = 6011;
