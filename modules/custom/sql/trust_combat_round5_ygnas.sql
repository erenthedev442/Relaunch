-- Ygnas: S-tier WHM/PLD healer. Restore unique Trust WS + leafkin anims.
-- Sacred Caper (ST Light+Rasp) / Phototrophic Blessing / Wrath / Deific Gambol (AoE).
-- Skill list was empty; trust IDs 3812–3815 (NM cousins 2979–2982).

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1113;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Ygnas',1113,3812), -- Sacred Caper
('TRUST_Ygnas',1113,3813), -- Phototrophic Blessing
('TRUST_Ygnas',1113,3814), -- Phototrophic Wrath
('TRUST_Ygnas',1113,3815); -- Deific Gambol

-- Enable Sacred Caper trust row if missing / commented in base dumps.
INSERT INTO `mob_skills` (`mob_skill_id`, `mob_anim_id`, `mob_skill_name`, `mob_skill_aoe`, `mob_skill_aoe_radius`, `mob_skill_distance`, `mob_anim_time`, `mob_prepare_time`, `mob_valid_targets`, `mob_skill_flag`, `mob_skill_param`, `knockback`, `primary_sc`, `secondary_sc`, `tertiary_sc`)
VALUES (3812, 2163, 'sacred_caper', 0, 0.0, 18.0, 2000, 1000, 4, 0, 0, 0, 0, 0, 0)
ON DUPLICATE KEY UPDATE
    `mob_anim_id` = VALUES(`mob_anim_id`),
    `mob_skill_name` = VALUES(`mob_skill_name`),
    `mob_skill_aoe` = VALUES(`mob_skill_aoe`),
    `mob_skill_distance` = VALUES(`mob_skill_distance`),
    `mob_valid_targets` = VALUES(`mob_valid_targets`);

UPDATE `mob_skills` SET
    `mob_anim_id` = 2163,
    `mob_skill_name` = 'sacred_caper',
    `mob_skill_aoe` = 0,
    `mob_skill_aoe_radius` = 0.0,
    `mob_skill_distance` = 18.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 1000,
    `mob_valid_targets` = 4,
    `mob_skill_flag` = 0,
    `primary_sc` = 0,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3812;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2164,
    `mob_skill_name` = 'phototrophic_blessing',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 0.0,
    `mob_skill_distance` = 20.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 1000,
    `mob_valid_targets` = 1,
    `mob_skill_flag` = 0,
    `primary_sc` = 0,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3813;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2165,
    `mob_skill_name` = 'phototrophic_wrath',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 0.0,
    `mob_skill_distance` = 20.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 1000,
    `mob_valid_targets` = 1,
    `mob_skill_flag` = 0,
    `primary_sc` = 0,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3814;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2166,
    `mob_skill_name` = 'deific_gambol',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 10.0,
    `mob_skill_distance` = 18.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 1000,
    `mob_valid_targets` = 4,
    `mob_skill_flag` = 0,
    `primary_sc` = 0,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3815;

-- WHM/PLD. No AA (script). Spell list 411 already complete.
UPDATE `mob_pools` SET
    `mJob` = 3,
    `sJob` = 7,
    `cmbSkill` = 11,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `skill_list_id` = 1113,
    `spellList` = 411
WHERE `poolid` = 5998;
