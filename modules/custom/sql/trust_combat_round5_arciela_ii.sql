-- Arciela II: RDM/BLM offensive support. Unique WS SC props + AoE Naakual.
-- Ascension/Descension are script-invoked (not TP list). Skill list 1132 unchanged set.

UPDATE `mob_skills` SET
    `mob_anim_id` = 400,
    `mob_skill_name` = 'ascension',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 18.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 4,
    `mob_skill_flag` = 4,
    `primary_sc` = 0,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3697;

UPDATE `mob_skills` SET
    `mob_anim_id` = 401,
    `mob_skill_name` = 'descension',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 18.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 4,
    `mob_skill_flag` = 4,
    `primary_sc` = 0,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3698;

-- Expunge Magic: Distortion / Scission
UPDATE `mob_skills` SET
    `mob_anim_id` = 402,
    `mob_skill_name` = 'expunge_magic',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 12.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 1000,
    `mob_valid_targets` = 4,
    `primary_sc` = 10,
    `secondary_sc` = 4,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3699;

-- Harmonic Displacement: Fusion / Reverberation
UPDATE `mob_skills` SET
    `mob_anim_id` = 403,
    `mob_skill_name` = 'harmonic_displacement',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 12.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 1000,
    `mob_valid_targets` = 4,
    `primary_sc` = 11,
    `secondary_sc` = 5,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3700;

-- Sight Unseen: Fragmentation / Compression
UPDATE `mob_skills` SET
    `mob_anim_id` = 404,
    `mob_skill_name` = 'sight_unseen',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 12.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 1000,
    `mob_valid_targets` = 4,
    `primary_sc` = 12,
    `secondary_sc` = 2,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3701;

-- Darkest Hour: Gravitation / Liquefaction
UPDATE `mob_skills` SET
    `mob_anim_id` = 405,
    `mob_skill_name` = 'darkest_hour',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 12.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 1000,
    `mob_valid_targets` = 4,
    `primary_sc` = 9,
    `secondary_sc` = 3,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3702;

-- Unceasing Dread: Paralyze, no SC
UPDATE `mob_skills` SET
    `mob_anim_id` = 406,
    `mob_skill_name` = 'unceasing_dread',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 12.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 1000,
    `mob_valid_targets` = 4,
    `primary_sc` = 0,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3703;

-- Dignified Awe: Amnesia, no SC
UPDATE `mob_skills` SET
    `mob_anim_id` = 407,
    `mob_skill_name` = 'dignified_awe',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 12.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 1000,
    `mob_valid_targets` = 4,
    `primary_sc` = 0,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3704;

-- Naakual's Vengeance: AoE Light / Fusion, script CD (not on TP list)
UPDATE `mob_skills` SET
    `mob_anim_id` = 408,
    `mob_skill_name` = 'naakuals_vengeance',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 10.0,
    `mob_skill_distance` = 12.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 1000,
    `mob_valid_targets` = 4,
    `mob_skill_flag` = 0,
    `primary_sc` = 13,
    `secondary_sc` = 11,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3705;

-- Ensure WS list (no Ascension/Descension/Naakual on TP picker).
DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1132;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Arciela_II',1132,3699), -- Expunge Magic (Ascension)
('TRUST_Arciela_II',1132,3700), -- Harmonic Displacement (Ascension)
('TRUST_Arciela_II',1132,3701), -- Sight Unseen (Descension)
('TRUST_Arciela_II',1132,3702), -- Darkest Hour (Descension)
('TRUST_Arciela_II',1132,3703), -- Unceasing Dread (neutral)
('TRUST_Arciela_II',1132,3704); -- Dignified Awe (neutral)

-- RDM/BLM
UPDATE `mob_pools` SET
    `mJob` = 5,
    `sJob` = 4,
    `cmbSkill` = 3,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `skill_list_id` = 1132,
    `spellList` = 426
WHERE `poolid` = 6017;
