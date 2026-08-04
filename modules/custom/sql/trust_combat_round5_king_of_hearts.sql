-- King of Hearts: RDM/WHM Arcana. Replace sword WS with Cardian trust kit.
-- WS: Shuffle (Dispel) / Double Down / Bludgeon (after Level Up) / Deal Out (AoE).
-- Keep trust-model anims 344/345/427/428. Family 49 (Arcana) unchanged.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1104;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_King_of_Hearts',1104,3689), -- Shuffle
('TRUST_King_of_Hearts',1104,3690), -- Double Down
('TRUST_King_of_Hearts',1104,3691), -- Bludgeon (Level Up gated)
('TRUST_King_of_Hearts',1104,3692); -- Deal Out (AoE)

-- Trust Cardian WS anims / targeting. Deal Out is AoE.
UPDATE `mob_skills` SET
    `mob_anim_id` = 344,
    `mob_skill_name` = 'shuffle',
    `mob_skill_aoe` = 0,
    `mob_skill_aoe_radius` = 0.0,
    `mob_skill_distance` = 7.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 1500,
    `mob_valid_targets` = 4,
    `mob_skill_flag` = 0
WHERE `mob_skill_id` = 3689;

UPDATE `mob_skills` SET
    `mob_anim_id` = 345,
    `mob_skill_name` = 'double_down',
    `mob_skill_aoe` = 0,
    `mob_skill_aoe_radius` = 0.0,
    `mob_skill_distance` = 7.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 1500,
    `mob_valid_targets` = 4,
    `mob_skill_flag` = 0
WHERE `mob_skill_id` = 3690;

UPDATE `mob_skills` SET
    `mob_anim_id` = 427,
    `mob_skill_name` = 'bludgeon',
    `mob_skill_aoe` = 0,
    `mob_skill_aoe_radius` = 0.0,
    `mob_skill_distance` = 7.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 1500,
    `mob_valid_targets` = 4,
    `mob_skill_flag` = 0
WHERE `mob_skill_id` = 3691;

UPDATE `mob_skills` SET
    `mob_anim_id` = 428,
    `mob_skill_name` = 'deal_out',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 10.0,
    `mob_skill_distance` = 10.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 1500,
    `mob_valid_targets` = 4,
    `mob_skill_flag` = 0
WHERE `mob_skill_id` = 3692;

-- RDM/WHM, club skill (blunt Cardian hits). A-tier buffer melee chip via catalog.
UPDATE `mob_pools` SET
    `mJob` = 5,
    `sJob` = 3,
    `cmbSkill` = 11,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `skill_list_id` = 1104,
    `spellList` = 402
WHERE `poolid` = 5989;
