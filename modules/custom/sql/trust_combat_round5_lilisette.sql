-- Lilisette: restore unique DNC TP moves (was remapped to player dagger WS).
-- Anims 1712–1717. DNC/DNC Dagger.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1060;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Lilisette',1060,3308), -- Thorn Dance (self DEF)
('TRUST_Lilisette',1060,3309), -- Sensual Dance (party gaze ATK/MATT)
('TRUST_Lilisette',1060,3310), -- Dancer's Fury
('TRUST_Lilisette',1060,3311), -- Whirling Edge (AoE)
('TRUST_Lilisette',1060,3312), -- Rousing Samba (party crit)
('TRUST_Lilisette',1060,3313); -- Vivifying Waltz (party heal)

UPDATE `mob_skills` SET
    `mob_anim_id` = 1714,
    `mob_skill_name` = 'thorned_dance',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 18.0,
    `mob_valid_targets` = 1,
    `primary_sc` = 0,
    `secondary_sc` = 0
WHERE `mob_skill_id` = 3308;

UPDATE `mob_skills` SET
    `mob_anim_id` = 1715,
    `mob_skill_name` = 'sensual_dance',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 18.0,
    `mob_skill_distance` = 18.0,
    `mob_valid_targets` = 1,
    `primary_sc` = 0,
    `secondary_sc` = 0
WHERE `mob_skill_id` = 3309;

UPDATE `mob_skills` SET
    `mob_anim_id` = 1712,
    `mob_skill_name` = 'dancers_fury',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 0,
    `secondary_sc` = 0
WHERE `mob_skill_id` = 3310;

UPDATE `mob_skills` SET
    `mob_anim_id` = 1713,
    `mob_skill_name` = 'whirling_edge',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 8.0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 0,
    `secondary_sc` = 0
WHERE `mob_skill_id` = 3311;

UPDATE `mob_skills` SET
    `mob_anim_id` = 1716,
    `mob_skill_name` = 'rousing_samba',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 18.0,
    `mob_skill_distance` = 18.0,
    `mob_valid_targets` = 1,
    `primary_sc` = 0,
    `secondary_sc` = 0
WHERE `mob_skill_id` = 3312;

UPDATE `mob_skills` SET
    `mob_anim_id` = 1717,
    `mob_skill_name` = 'vivifying_waltz',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 18.0,
    `mob_skill_distance` = 18.0,
    `mob_valid_targets` = 1,
    `primary_sc` = 0,
    `secondary_sc` = 0
WHERE `mob_skill_id` = 3313;

-- DNC/DNC, Dagger.
UPDATE `mob_pools` SET
    `mJob` = 19,
    `sJob` = 19,
    `cmbSkill` = 2
WHERE `poolid` = 5945;
