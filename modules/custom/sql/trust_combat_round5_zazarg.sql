-- Zazarg: restore Meteoric Impact (list had Victory Smite placeholder).
-- MNK/MNK H2H. Howling Fist / Dragon Kick / Asuran Fists / Meteoric Impact.
-- Focus gated in script (ACC soft vs EVA). ASAP@1000. C bruiser path.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1039;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Zazarg',1039,7),    -- Howling Fist
('TRUST_Zazarg',1039,8),    -- Dragon Kick
('TRUST_Zazarg',1039,9),    -- Asuran Fists
('TRUST_Zazarg',1039,2091); -- Meteoric Impact (AoE + Petrify; Darkness/Frag)

-- Affirm player MNK WS anims / SC.
UPDATE `mob_skills` SET
    `mob_anim_id` = 22,
    `mob_skill_name` = 'howling_fist',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 1,
    `secondary_sc` = 8,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 7;

UPDATE `mob_skills` SET
    `mob_anim_id` = 23,
    `mob_skill_name` = 'dragon_kick',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 12,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 8;

UPDATE `mob_skills` SET
    `mob_anim_id` = 24,
    `mob_skill_name` = 'asuran_fists',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 9,
    `secondary_sc` = 3,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 9;

-- Meteoric Impact: capture anim 1430, AoE around user, Darkness/Fragmentation.
UPDATE `mob_skills` SET
    `mob_anim_id` = 1430,
    `mob_skill_name` = 'meteoric_impact',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 10.0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `mob_prepare_time` = 1500,
    `primary_sc` = 14,
    `secondary_sc` = 12,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 2091;

-- Keep Trust duplicate row aligned (unused by list; prevent drift).
UPDATE `mob_skills` SET
    `mob_anim_id` = 1430,
    `mob_skill_name` = 'meteoric_impact',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 10.0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `mob_prepare_time` = 1500,
    `primary_sc` = 14,
    `secondary_sc` = 12,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3240;

-- MNK/MNK, Hand-to-Hand.
UPDATE `mob_pools` SET
    `mJob` = 2,
    `sJob` = 2,
    `cmbSkill` = 1,
    `cmbDelay` = 240,
    `skill_list_id` = 1039
WHERE `poolid` = 5924;
