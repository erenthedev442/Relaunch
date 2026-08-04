-- Luzaf: restore unique COR WS kit (was remapped to player gun WS).
-- Anims 2310 / 263 / 2312 / 2313. COR/NIN Marksmanship.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1043;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Luzaf',1043,3252), -- Bisection (Fragmentation/Scission)
('TRUST_Luzaf',1043,3253), -- Leaden Salute (Gravitation/Transfixion)
('TRUST_Luzaf',1043,3254), -- Akimbo Shot (Reverberation/Detonation)
('TRUST_Luzaf',1043,3255); -- Grisly Horizon (Gravitation)

UPDATE `mob_skills` SET
    `mob_anim_id` = 2310,
    `mob_skill_name` = 'bisection',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `knockback` = 0,
    `primary_sc` = 12,
    `secondary_sc` = 4,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3252;

UPDATE `mob_skills` SET
    `mob_anim_id` = 263,
    `mob_skill_name` = 'leaden_salute',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 15.0,
    `mob_valid_targets` = 4,
    `knockback` = 0,
    `primary_sc` = 9,
    `secondary_sc` = 1,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3253;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2312,
    `mob_skill_name` = 'akimbo_shot',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 15.0,
    `mob_valid_targets` = 4,
    `knockback` = 0,
    `primary_sc` = 5,
    `secondary_sc` = 6,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3254;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2313,
    `mob_skill_name` = 'grisly_horizon',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 8.0,
    `mob_skill_distance` = 15.0,
    `mob_valid_targets` = 4,
    `knockback` = 0,
    `primary_sc` = 9,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3255;

-- COR/NIN, Marksmanship, gun delay.
UPDATE `mob_pools` SET
    `mJob` = 17,
    `sJob` = 13,
    `cmbSkill` = 26,
    `cmbDelay` = 600
WHERE `poolid` = 5928;
