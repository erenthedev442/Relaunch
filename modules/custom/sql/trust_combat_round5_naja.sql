-- Naja Salaheem: affirm MNK/WAR Club kit + Peacebreaker SC / anim.
-- True Strike / Hexa Strike / Peacebreaker / Black Halo (HIGHEST last).

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1027;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Naja_Salaheem',1027,166),  -- True Strike
('TRUST_Naja_Salaheem',1027,168),  -- Hexa Strike
('TRUST_Naja_Salaheem',1027,3215), -- Peacebreaker
('TRUST_Naja_Salaheem',1027,169);  -- Black Halo (HIGHEST)

-- Affirm standard club WS anims / SC props.
UPDATE `mob_skills` SET
    `mob_anim_id` = 82,
    `mob_skill_name` = 'true_strike',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 8,
    `secondary_sc` = 6,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 166;

UPDATE `mob_skills` SET
    `mob_anim_id` = 84,
    `mob_skill_name` = 'hexa_strike',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 11,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 168;

UPDATE `mob_skills` SET
    `mob_anim_id` = 85,
    `mob_skill_name` = 'black_halo',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 12,
    `secondary_sc` = 2,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 169;

-- Peacebreaker: Distortion / Reverberation.
UPDATE `mob_skills` SET
    `mob_anim_id` = 1483,
    `mob_skill_name` = 'peacebreaker',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `knockback` = 0,
    `primary_sc` = 10,
    `secondary_sc` = 5,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3215;

-- MNK/WAR, Club, delay 240.
UPDATE `mob_pools` SET
    `mJob` = 2,
    `sJob` = 1,
    `cmbSkill` = 11,
    `cmbDelay` = 240
WHERE `poolid` = 5912;
