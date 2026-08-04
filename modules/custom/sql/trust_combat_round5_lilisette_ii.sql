-- Lilisette II: ST Whirling Edge / Dancer's Fury / Vivifying Waltz.
-- Rousing Samba is a 350-TP JA (skill 3298, NO_TP_COST), not a WS-list move.
-- Was remapped to player dagger WS.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1128;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Lilisette_II',1128,3310), -- Dancer's Fury
('TRUST_Lilisette_II',1128,3544); -- Whirling Edge (single-target)
-- Vivifying Waltz (3313) and Rousing Samba II (3298) are script-driven, not on the WS list.

-- Rousing Samba II (JA-style; script spends 350 TP).
INSERT INTO `mob_skills` (`mob_skill_id`, `mob_anim_id`, `mob_skill_name`, `mob_skill_aoe`, `mob_skill_aoe_radius`, `mob_skill_distance`, `mob_anim_time`, `mob_prepare_time`, `mob_valid_targets`, `mob_skill_flag`, `mob_skill_param`, `knockback`, `primary_sc`, `secondary_sc`, `tertiary_sc`)
VALUES (3298,1716,'rousing_samba_ii',1,18.0,18.0,2000,500,1,4,0,0,0,0,0)
ON DUPLICATE KEY UPDATE
    `mob_anim_id` = 1716,
    `mob_skill_name` = 'rousing_samba_ii',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 18.0,
    `mob_skill_distance` = 18.0,
    `mob_valid_targets` = 1,
    `mob_skill_flag` = 4,
    `primary_sc` = 0,
    `secondary_sc` = 0;

-- Affirm Dancer's Fury SC props (closes common chains).
UPDATE `mob_skills` SET
    `mob_anim_id` = 1712,
    `mob_skill_name` = 'dancers_fury',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 11,
    `secondary_sc` = 8
WHERE `mob_skill_id` = 3310;

-- Single-target Whirling Edge (Alter Ego II).
UPDATE `mob_skills` SET
    `mob_anim_id` = 1713,
    `mob_skill_name` = 'whirling_edge',
    `mob_skill_aoe` = 0,
    `mob_skill_aoe_radius` = 0.0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 10,
    `secondary_sc` = 4
WHERE `mob_skill_id` = 3544;

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

-- DNC/WAR, Dagger, faster delay.
UPDATE `mob_pools` SET
    `mJob` = 19,
    `sJob` = 1,
    `cmbSkill` = 2,
    `cmbDelay` = 180
WHERE `poolid` = 6013;
