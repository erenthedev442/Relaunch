-- Nashmeira II: restore sole Imperial Authority WS (was remapped to dagger WS).
-- WHM/PUP Hand-to-Hand. Shares skill 3243 with Nashmeira I.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1127;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Nashmeira_II',1127,3243); -- Imperial Authority

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

-- WHM/PUP, Hand-to-Hand.
UPDATE `mob_pools` SET
    `mJob` = 3,
    `sJob` = 18,
    `cmbSkill` = 1,
    `cmbDelay` = 480
WHERE `poolid` = 6012;
