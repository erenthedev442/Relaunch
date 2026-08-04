-- Mumor: affirm DNC/WAR Club + Skullbreaker kit (retail-only WS).
-- Anim 81, Induration/Reverberation.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1061;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Mumor',1061,165); -- Skullbreaker

UPDATE `mob_skills` SET
    `mob_anim_id` = 81,
    `mob_skill_name` = 'skullbreaker',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `knockback` = 0,
    `primary_sc` = 7,
    `secondary_sc` = 5,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 165;

-- DNC/WAR, Club, delay 240.
UPDATE `mob_pools` SET
    `mJob` = 19,
    `sJob` = 1,
    `cmbSkill` = 11,
    `cmbDelay` = 240
WHERE `poolid` = 5946;
