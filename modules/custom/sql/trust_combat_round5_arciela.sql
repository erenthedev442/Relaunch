-- Arciela: support RDM/PLD. Replace sword WS with unique Bellatrix kit.
-- WS: Dynastic Gravitas / Illustrious Aid / Guiding Light.
-- Bellatrix Light/Shadows are stance abilities (script-invoked, not TP list).
-- Light magical AA via skill list 2103 (trust anims 199-201).

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1080;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Arciela',1080,3451), -- Dynastic Gravitas (Shadows)
('TRUST_Arciela',1080,3452), -- Illustrious Aid (Light, multi-yellow)
('TRUST_Arciela',1080,3453); -- Guiding Light (either)

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 2103;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Arciela_Melee',2103,3117), -- arciela_auto_attack
('TRUST_Arciela_Melee',2103,3118), -- arciela_auto_attack_b
('TRUST_Arciela_Melee',2103,3119); -- arciela_auto_attack_c

-- Stance abilities: self-target, no TP cost. Keep trust-model anims 205/206.
UPDATE `mob_skills` SET
    `mob_anim_id` = 205,
    `mob_skill_name` = 'bellatrix_of_light',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 1,
    `mob_skill_flag` = 4
WHERE `mob_skill_id` = 3115;

UPDATE `mob_skills` SET
    `mob_anim_id` = 206,
    `mob_skill_name` = 'bellatrix_of_shadows',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 1,
    `mob_skill_flag` = 4
WHERE `mob_skill_id` = 3116;

-- Light AA (trust-model anims 199-201). Flag 4 = no TP cost.
INSERT INTO `mob_skills` (`mob_skill_id`, `mob_anim_id`, `mob_skill_name`, `mob_skill_aoe`, `mob_skill_aoe_radius`, `mob_skill_distance`, `mob_anim_time`, `mob_prepare_time`, `mob_valid_targets`, `mob_skill_flag`, `mob_skill_param`, `knockback`, `primary_sc`, `secondary_sc`, `tertiary_sc`)
VALUES
(3117, 199, 'arciela_auto_attack',   0, 0.0, 7.0, 2000, 0, 4, 4, 0, 0, 0, 0, 0),
(3118, 200, 'arciela_auto_attack_b', 0, 0.0, 7.0, 2000, 0, 4, 4, 0, 0, 0, 0, 0),
(3119, 201, 'arciela_auto_attack_c', 0, 0.0, 7.0, 2000, 0, 4, 4, 0, 0, 0, 0, 0)
ON DUPLICATE KEY UPDATE
    `mob_anim_id` = VALUES(`mob_anim_id`),
    `mob_skill_name` = VALUES(`mob_skill_name`),
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 4,
    `mob_skill_flag` = 4;

UPDATE `mob_skills` SET
    `mob_anim_id` = 184,
    `mob_skill_name` = 'dynastic_gravitas',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 10.0,
    `mob_skill_distance` = 12.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 1000,
    `mob_valid_targets` = 4,
    `mob_skill_flag` = 0
WHERE `mob_skill_id` = 3451;

UPDATE `mob_skills` SET
    `mob_anim_id` = 304,
    `mob_skill_name` = 'illustrious_aid',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 0.0,
    `mob_skill_distance` = 20.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 1000,
    `mob_valid_targets` = 1,
    `mob_skill_flag` = 0
WHERE `mob_skill_id` = 3452;

UPDATE `mob_skills` SET
    `mob_anim_id` = 303,
    `mob_skill_name` = 'guiding_light',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 0.0,
    `mob_skill_distance` = 20.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 1000,
    `mob_valid_targets` = 1,
    `mob_skill_flag` = 0
WHERE `mob_skill_id` = 3453;

-- Add missing Addle / Dispel to spell list 378.
DELETE FROM `mob_spell_lists` WHERE `spell_list_id` = 378 AND `spell_id` IN (260, 286);

INSERT INTO `mob_spell_lists` VALUES
('TRUST_Arciela',378,260,32,255), -- dispel
('TRUST_Arciela',378,286,83,255); -- addle

-- RDM/PLD, sword skill for weapon rating (AA is skill-attack light).
UPDATE `mob_pools` SET
    `mJob` = 5,
    `sJob` = 7,
    `cmbSkill` = 3,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `skill_list_id` = 1080,
    `spellList` = 378
WHERE `poolid` = 5965;
