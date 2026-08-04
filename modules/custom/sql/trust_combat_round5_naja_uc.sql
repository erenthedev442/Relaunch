-- Naja Salaheem UC: MNK/WAR A-tier club skirmisher.
-- WS chosen exclusively in Lua; pool skill_list_id = 0.
-- Document full kit on list 1123.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1123;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Naja_Salaheem_UC',1123,3215), -- Peacebreaker (5)
('TRUST_Naja_Salaheem_UC',1123,168),  -- Hexa Strike (25)
('TRUST_Naja_Salaheem_UC',1123,3502), -- Nott (50)
('TRUST_Naja_Salaheem_UC',1123,169),  -- Black Halo (60)
('TRUST_Naja_Salaheem_UC',1123,3503); -- Justicebreaker (70)

-- Justicebreaker: Distortion / Gravitation (Darkness path).
UPDATE `mob_skills` SET
    `mob_anim_id` = 85,
    `mob_skill_name` = 'justicebreaker',
    `mob_skill_aoe` = 0,
    `mob_skill_aoe_radius` = 0.0,
    `mob_skill_distance` = 7.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 4,
    `primary_sc` = 10,
    `secondary_sc` = 8,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3503;

-- Nott: self-target heal (HP; MP if present).
UPDATE `mob_skills` SET
    `mob_anim_id` = 89,
    `mob_skill_name` = 'nott',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 1,
    `primary_sc` = 0,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3502;

-- Peacebreaker utility anim / SC.
UPDATE `mob_skills` SET
    `mob_anim_id` = 1483,
    `mob_skill_name` = 'peacebreaker',
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 4,
    `primary_sc` = 10,
    `secondary_sc` = 5
WHERE `mob_skill_id` = 3215;

-- Affirm Hexa / Black Halo club anims.
UPDATE `mob_skills` SET
    `mob_anim_id` = 84,
    `mob_skill_name` = 'hexa_strike',
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 4
WHERE `mob_skill_id` = 168;

UPDATE `mob_skills` SET
    `mob_anim_id` = 85,
    `mob_skill_name` = 'black_halo',
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 4
WHERE `mob_skill_id` = 169;

UPDATE `mob_pools` SET
    `mJob` = 2,
    `sJob` = 1,
    `cmbSkill` = 11,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `skill_list_id` = 0,
    `spellList` = 0
WHERE `poolid` = 6008;
