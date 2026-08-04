-- Najelith: restore dagger/bow kit (base had polearm Double Thrust…Impulse).
-- RNG/RNG. Sidewinder / Empyreal / Typhonic Arrow (conal+Bind) / Cyclone.
-- Cyclone last so CLOSER@1500 HIGHEST opener prefers it. NO_MOVE hybrid in Lua.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1044;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Najelith',1044,196),  -- Sidewinder
('TRUST_Najelith',1044,199),  -- Empyreal Arrow
('TRUST_Najelith',1044,2090), -- Typhonic Arrow (conal Bind; Light/Distortion)
('TRUST_Najelith',1044,20);   -- Cyclone (preferred non-SC WS — last for HIGHEST opener)

UPDATE `mob_skills` SET
    `mob_anim_id` = 195,
    `mob_skill_name` = 'sidewinder',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 15.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 5,
    `secondary_sc` = 1,
    `tertiary_sc` = 6
WHERE `mob_skill_id` = 196;

UPDATE `mob_skills` SET
    `mob_anim_id` = 221,
    `mob_skill_name` = 'empyreal_arrow',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 15.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 11,
    `secondary_sc` = 1,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 199;

-- Typhonic Arrow: capture anim 1429, conal AoE, Light/Distortion.
UPDATE `mob_skills` SET
    `mob_anim_id` = 1429,
    `mob_skill_name` = 'typhonic_arrow',
    `mob_skill_aoe` = 4,
    `mob_skill_aoe_radius` = 10.0,
    `mob_skill_distance` = 15.0,
    `mob_valid_targets` = 4,
    `mob_prepare_time` = 1500,
    `primary_sc` = 13,
    `secondary_sc` = 10,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 2090;

UPDATE `mob_skills` SET
    `mob_anim_id` = 1429,
    `mob_skill_name` = 'typhonic_arrow',
    `mob_skill_aoe` = 4,
    `mob_skill_aoe_radius` = 10.0,
    `mob_skill_distance` = 15.0,
    `mob_valid_targets` = 4,
    `mob_prepare_time` = 1500,
    `primary_sc` = 13,
    `secondary_sc` = 10,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3239;

UPDATE `mob_skills` SET
    `mob_anim_id` = 35,
    `mob_skill_name` = 'cyclone',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 8.0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 6,
    `secondary_sc` = 8,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 20;

-- RNG/RNG, Dagger AA (Cyclone); RA via gambit.
UPDATE `mob_pools` SET
    `mJob` = 11,
    `sJob` = 11,
    `cmbSkill` = 2,
    `cmbDelay` = 200,
    `cmbDmgMult` = 100,
    `skill_list_id` = 1044
WHERE `poolid` = 5929;
