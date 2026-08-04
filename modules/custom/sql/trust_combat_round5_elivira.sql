-- Elivira: hybrid sword AA + Marksmanship RA (was Marksmanship-as-AA only).
-- RNG/WAR. Split / Slug / Heavy / Coronach. NO_MOVE; Barrage@TP<1000; CLOSER@1000.
-- C ranged_dd skirmisher path.

-- Affirm marksmanship WS anims / SC props.
UPDATE `mob_skills` SET
    `mob_anim_id` = 197,
    `mob_skill_name` = 'split_shot',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 15.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 5,
    `secondary_sc` = 1,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 209;

UPDATE `mob_skills` SET
    `mob_anim_id` = 200,
    `mob_skill_name` = 'slug_shot',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 15.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 5,
    `secondary_sc` = 1,
    `tertiary_sc` = 6
WHERE `mob_skill_id` = 212;

UPDATE `mob_skills` SET
    `mob_anim_id` = 223,
    `mob_skill_name` = 'heavy_shot',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 15.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 11,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 214;

UPDATE `mob_skills` SET
    `mob_anim_id` = 226,
    `mob_skill_name` = 'coronach',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 15.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 14,
    `secondary_sc` = 12,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 216;

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1056;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Elivira',1056,209), -- Split Shot
('TRUST_Elivira',1056,212), -- Slug Shot
('TRUST_Elivira',1056,214), -- Heavy Shot
('TRUST_Elivira',1056,216); -- Coronach

-- RNG/WAR: Sword AA (melee if in range); RA via gambit. Delay 240 rapier/sword.
UPDATE `mob_pools` SET
    `mJob` = 11,
    `sJob` = 1,
    `cmbSkill` = 3,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `skill_list_id` = 1056
WHERE `poolid` = 5941;
