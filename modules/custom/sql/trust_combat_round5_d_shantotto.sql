-- Domina Shantotto: restore scythe kit (list was empty) + darkness-only nukes.
-- BLM/DRK. Guillotine / Cross Reaper / Shadow of Death / Salvation Scythe.
-- Opens with T5 volley then melees; occasional nukes if not top enmity. ASAP@1000.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1049;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_D_Shantotto',1049,102),  -- Guillotine
('TRUST_D_Shantotto',1049,103),  -- Cross Reaper
('TRUST_D_Shantotto',1049,98),   -- Shadow of Death
('TRUST_D_Shantotto',1049,3264); -- Salvation Scythe (AoE Dark; Poison/Bio/Para/Slow)

UPDATE `mob_skills` SET
    `mob_anim_id` = 67,
    `mob_skill_name` = 'guillotine',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 7,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 102;

UPDATE `mob_skills` SET
    `mob_anim_id` = 68,
    `mob_skill_name` = 'cross_reaper',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 10,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 103;

UPDATE `mob_skills` SET
    `mob_anim_id` = 63,
    `mob_skill_name` = 'shadow_of_death',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `primary_sc` = 7,
    `secondary_sc` = 5,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 98;

UPDATE `mob_skills` SET
    `mob_anim_id` = 2230,
    `mob_skill_name` = 'salvation_scythe',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 8.0,
    `mob_skill_distance` = 7.0,
    `mob_valid_targets` = 4,
    `mob_prepare_time` = 1500,
    `primary_sc` = 13,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3264;

-- Darkness-aligned nukes only (Earth / Ice / Water).
DELETE FROM `mob_spell_lists` WHERE `spell_list_id` = 346;

INSERT INTO `mob_spell_lists` VALUES
('TRUST_D_Shantotto',346,149,17,255), -- blizzard
('TRUST_D_Shantotto',346,150,42,255), -- blizzard_ii
('TRUST_D_Shantotto',346,151,64,255), -- blizzard_iii
('TRUST_D_Shantotto',346,152,74,255), -- blizzard_iv
('TRUST_D_Shantotto',346,153,89,255), -- blizzard_v
('TRUST_D_Shantotto',346,159,1,255),  -- stone
('TRUST_D_Shantotto',346,160,26,255), -- stone_ii
('TRUST_D_Shantotto',346,161,51,255), -- stone_iii
('TRUST_D_Shantotto',346,162,68,255), -- stone_iv
('TRUST_D_Shantotto',346,163,77,255), -- stone_v
('TRUST_D_Shantotto',346,169,5,255),  -- water
('TRUST_D_Shantotto',346,170,30,255), -- water_ii
('TRUST_D_Shantotto',346,171,55,255), -- water_iii
('TRUST_D_Shantotto',346,172,70,255), -- water_iv
('TRUST_D_Shantotto',346,173,80,255); -- water_v

-- BLM/DRK, Scythe.
UPDATE `mob_pools` SET
    `mJob` = 4,
    `sJob` = 8,
    `cmbSkill` = 7,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `skill_list_id` = 1049,
    `spell_list_id` = 346
WHERE `poolid` = 5934;
