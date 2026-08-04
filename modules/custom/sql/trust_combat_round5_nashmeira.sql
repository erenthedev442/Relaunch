-- Nashmeira: restore sole Imperial Authority WS (was remapped to dagger WS).
-- PUP/WHM Hand-to-Hand. Anim 2034. Fragmentation / Distortion.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1038;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Nashmeira',1038,3243); -- Imperial Authority

UPDATE `mob_skills` SET
    `mob_anim_id` = 2034,
    `mob_skill_name` = 'imperial_authority',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `knockback` = 0,
    `primary_sc` = 12,
    `secondary_sc` = 10,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3243;

-- PUP/WHM, Hand-to-Hand (fists), delay 240.
UPDATE `mob_pools` SET
    `mJob` = 18,
    `sJob` = 3,
    `cmbSkill` = 1,
    `cmbDelay` = 240
WHERE `poolid` = 5923;
