-- Semih Lafihna: restore Trust archery kit (base had Empyreal/Refulgent player WS).
-- RNG/WAR. Arching / Stellar (AoE Eva Down) / Lux (Def Down) / Sidewinder.
-- Sidewinder last so CLOSER@2000 HIGHEST opener prefers it for damage.
-- Unique anims 2476–2479 on Trust skill IDs 3487–3490.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1055;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Semih_Lafihna',1055,3488), -- Arching Arrow (Trust anim)
('TRUST_Semih_Lafihna',1055,3489), -- Stellar Arrow (AoE; Darkness/Gravitation)
('TRUST_Semih_Lafihna',1055,3490), -- Lux Arrow (Fragmentation/Distortion)
('TRUST_Semih_Lafihna',1055,3487); -- Sidewinder (preferred non-SC WS — last for HIGHEST opener)

UPDATE `mob_skills` SET
    `mob_anim_id` = 2477,
    `mob_skill_name` = 'sidewinder',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 16.0,
    `mob_valid_targets` = 4,
    `mob_prepare_time` = 1500,
    `primary_sc` = 5,
    `secondary_sc` = 1,
    `tertiary_sc` = 6
WHERE `mob_skill_id` = 3487;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2476,
    `mob_skill_name` = 'arching_arrow',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 16.0,
    `mob_valid_targets` = 4,
    `mob_prepare_time` = 1500,
    `primary_sc` = 11,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3488;

-- Stellar Arrow: target-centered AoE, Darkness/Gravitation.
UPDATE `mob_skills` SET
    `mob_anim_id` = 2478,
    `mob_skill_name` = 'stellar_arrow',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 8.0,
    `mob_skill_distance` = 16.0,
    `mob_valid_targets` = 4,
    `mob_prepare_time` = 1500,
    `primary_sc` = 14,
    `secondary_sc` = 9,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3489;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2479,
    `mob_skill_name` = 'lux_arrow',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 16.0,
    `mob_valid_targets` = 4,
    `mob_prepare_time` = 1500,
    `primary_sc` = 12,
    `secondary_sc` = 10,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3490;

-- RNG/WAR, Archery AA via RATTACK. Delay + Store TP package → ~252 TP/hit.
UPDATE `mob_pools` SET
    `mJob` = 11,
    `sJob` = 1,
    `cmbSkill` = 25,
    `cmbDelay` = 500,
    `cmbDmgMult` = 200,
    `skill_list_id` = 1055
WHERE `poolid` = 5940;
