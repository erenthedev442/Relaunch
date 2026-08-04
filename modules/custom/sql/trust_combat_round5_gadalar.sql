-- Gadalar: restore scythe kit (list was empty) + Salamander Flame.
-- BLM/BLM. Spinning / Spiral Hell / Vorpal / Salamander (favored; Light/Fusion; Dia III).
-- Firaga I–III + Blaze Spikes. ASAP@1000. MP convert on physical hits in Lua.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1034;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Gadalar',1034,100),  -- Spinning Scythe
('TRUST_Gadalar',1034,104),  -- Spiral Hell
('TRUST_Gadalar',1034,101),  -- Vorpal Scythe
('TRUST_Gadalar',1034,2089); -- Salamander Flame (preferred — last for HIGHEST opener)

UPDATE `mob_skills` SET
    `mob_anim_id` = 65,
    `mob_skill_name` = 'spinning_scythe',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 4.0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 5,
    `secondary_sc` = 4,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 100;

UPDATE `mob_skills` SET
    `mob_anim_id` = 69,
    `mob_skill_name` = 'spiral_hell',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 10,
    `secondary_sc` = 4,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 104;

UPDATE `mob_skills` SET
    `mob_anim_id` = 66,
    `mob_skill_name` = 'vorpal_scythe',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 1,
    `secondary_sc` = 4,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 101;

-- Salamander Flame: Fire AoE, Light/Fusion, Dia III in Lua.
UPDATE `mob_skills` SET
    `mob_anim_id` = 1428,
    `mob_skill_name` = 'salamander_flame',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 10.0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `mob_prepare_time` = 1500,
    `primary_sc` = 13,
    `secondary_sc` = 11,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 2089;

-- BLM/BLM, Scythe.
UPDATE `mob_pools` SET
    `mJob` = 4,
    `sJob` = 4,
    `cmbSkill` = 7,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `skill_list_id` = 1034,
    `spellList` = 331
WHERE `poolid` = 5919;
