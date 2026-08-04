-- Kupipi: WHM/WHM C-tier starter healer. Starlight / Moonlight (MP restore).
-- Add Protect/Shell I–V; remove Flash (not on retail kit). Affirm club WS anims.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1013;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Kupipi',1013,163), -- Starlight
('TRUST_Kupipi',1013,164); -- Moonlight (HIGHEST)

UPDATE `mob_skills` SET
    `mob_anim_id` = 79,
    `mob_skill_name` = 'starlight',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 1,
    `primary_sc` = 0,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 163;

UPDATE `mob_skills` SET
    `mob_anim_id` = 80,
    `mob_skill_name` = 'moonlight',
    `mob_skill_aoe` = 2,
    `mob_skill_aoe_radius` = 6.0,
    `mob_skill_distance` = 7.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 1,
    `primary_sc` = 0,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 164;

DELETE FROM `mob_spell_lists` WHERE `spell_list_id` = 310;

INSERT INTO `mob_spell_lists` VALUES
('TRUST_Kupipi',310,1,1,255),    -- cure
('TRUST_Kupipi',310,2,11,255),   -- cure_ii
('TRUST_Kupipi',310,3,21,255),   -- cure_iii
('TRUST_Kupipi',310,4,41,255),   -- cure_iv
('TRUST_Kupipi',310,5,61,255),   -- cure_v
('TRUST_Kupipi',310,6,80,255),   -- cure_vi
('TRUST_Kupipi',310,14,6,255),   -- poisona
('TRUST_Kupipi',310,15,9,255),   -- paralyna
('TRUST_Kupipi',310,16,14,255),  -- blindna
('TRUST_Kupipi',310,17,19,255),  -- silena
('TRUST_Kupipi',310,18,39,255),  -- stona
('TRUST_Kupipi',310,19,34,255),  -- viruna
('TRUST_Kupipi',310,20,29,255),  -- cursna
('TRUST_Kupipi',310,43,7,255),   -- protect
('TRUST_Kupipi',310,44,27,255),  -- protect_ii
('TRUST_Kupipi',310,45,47,255),  -- protect_iii
('TRUST_Kupipi',310,46,63,255),  -- protect_iv
('TRUST_Kupipi',310,47,76,255),  -- protect_v
('TRUST_Kupipi',310,48,17,255),  -- shell
('TRUST_Kupipi',310,49,37,255),  -- shell_ii
('TRUST_Kupipi',310,50,57,255),  -- shell_iii
('TRUST_Kupipi',310,51,68,255),  -- shell_iv
('TRUST_Kupipi',310,52,76,255),  -- shell_v
('TRUST_Kupipi',310,56,13,255),  -- slow
('TRUST_Kupipi',310,58,6,255),   -- paralyze
('TRUST_Kupipi',310,125,7,255),  -- protectra
('TRUST_Kupipi',310,126,27,255), -- protectra_ii
('TRUST_Kupipi',310,127,47,255), -- protectra_iii
('TRUST_Kupipi',310,128,63,255), -- protectra_iv
('TRUST_Kupipi',310,129,75,255), -- protectra_v
('TRUST_Kupipi',310,130,17,255), -- shellra
('TRUST_Kupipi',310,131,37,255), -- shellra_ii
('TRUST_Kupipi',310,132,57,255), -- shellra_iii
('TRUST_Kupipi',310,133,68,255), -- shellra_iv
('TRUST_Kupipi',310,134,75,255), -- shellra_v
('TRUST_Kupipi',310,143,32,255); -- erase

-- WHM/WHM, club (Starlight/Moonlight).
UPDATE `mob_pools` SET
    `mJob` = 3,
    `sJob` = 3,
    `cmbSkill` = 11,
    `cmbDelay` = 230,
    `cmbDmgMult` = 40,
    `skill_list_id` = 1013,
    `spellList` = 310
WHERE `poolid` = 5898;
