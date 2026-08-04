-- Lehko Habhoka: restore unique Trust WS (Inspirit / Debonair / Iridal / Lunar).
-- round3 remapped him to player dagger WS (Wasp…Exenterator), wrong kit/anims.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1037;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Lehko_Habhoka',1037,3232), -- Iridal Pierce (AoE Light)
('TRUST_Lehko_Habhoka',1037,3233), -- Lunar Revolution (conal)
('TRUST_Lehko_Habhoka',1037,3231), -- Debonair Rush
('TRUST_Lehko_Habhoka',1037,3230); -- Inspirit (AoE HP+MP+Erase)

UPDATE `mob_skills` SET
    `mob_anim_id` = 1782,
    `mob_skill_name` = 'inspirit',
    `mob_skill_aoe` = 1,
    `mob_skill_distance` = 20.0,
    `mob_valid_targets` = 1,
    `primary_sc` = 0,
    `secondary_sc` = 0
WHERE `mob_skill_id` = 3230;

UPDATE `mob_skills` SET
    `mob_anim_id` = 1783,
    `mob_skill_name` = 'debonair_rush',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 8,
    `secondary_sc` = 0
WHERE `mob_skill_id` = 3231;

UPDATE `mob_skills` SET
    `mob_anim_id` = 1784,
    `mob_skill_name` = 'iridal_pierce',
    `mob_skill_aoe` = 1,
    `mob_skill_distance` = 12.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 13,
    `secondary_sc` = 12
WHERE `mob_skill_id` = 3232;

UPDATE `mob_skills` SET
    `mob_anim_id` = 1785,
    `mob_skill_name` = 'lunar_revolution',
    `mob_skill_aoe` = 4,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 9,
    `secondary_sc` = 5
WHERE `mob_skill_id` = 3233;

-- THF/BLM, Dagger.
UPDATE `mob_pools` SET
    `mJob` = 6,
    `sJob` = 4,
    `cmbSkill` = 2
WHERE `poolid` = 5922;
