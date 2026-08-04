-- Uka Totlihn: affirm DNC/WAR Club + Judgment kit (retail-only WS).
-- Anim 83, Impaction. Holds Judgment @2000 (no skillchains).

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1062;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Uka_Totlihn',1062,167); -- Judgment

UPDATE `mob_skills` SET
    `mob_anim_id` = 83,
    `mob_skill_name` = 'judgment',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 8,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 167;

-- DNC/WAR, Club, delay 240.
UPDATE `mob_pools` SET
    `mJob` = 19,
    `sJob` = 1,
    `cmbSkill` = 11,
    `cmbDelay` = 240,
    `skill_list_id` = 1062
WHERE `poolid` = 5947;
