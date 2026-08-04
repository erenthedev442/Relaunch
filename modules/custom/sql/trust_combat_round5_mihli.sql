-- Mihli Aliapoh: WHM/WHM C-tier healer. Club WS + Scouring Bubbles (AoE water).
-- Weight Scouring Bubbles in skill list (RANDOM prefer). Strip Erase/Esuna (not retail).

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1024;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Mihli_Aliapoh',1024,166),  -- True Strike
('TRUST_Mihli_Aliapoh',1024,162),  -- Brainshaker
('TRUST_Mihli_Aliapoh',1024,168),  -- Hexa Strike
('TRUST_Mihli_Aliapoh',1024,3203); -- Scouring Bubbles (prefer via AI)

-- Club WS anims / SC props.
UPDATE `mob_skills` SET
    `mob_anim_id` = 82,
    `mob_skill_name` = 'true_strike',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 4,
    `primary_sc` = 8,
    `secondary_sc` = 6,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 166;

UPDATE `mob_skills` SET
    `mob_anim_id` = 78,
    `mob_skill_name` = 'brainshaker',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 4,
    `primary_sc` = 5,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 162;

UPDATE `mob_skills` SET
    `mob_anim_id` = 84,
    `mob_skill_name` = 'hexa_strike',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 4,
    `primary_sc` = 11,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 168;

-- Scouring Bubbles: AoE water, Darkness / Distortion.
UPDATE `mob_skills` SET
    `mob_anim_id` = 1431,
    `mob_skill_name` = 'scouring_bubbles',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 8.0,
    `mob_skill_distance` = 7.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 1500,
    `mob_valid_targets` = 4,
    `primary_sc` = 14,
    `secondary_sc` = 10,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3203;

DELETE FROM `mob_spell_lists` WHERE `spell_list_id` = 321;

INSERT INTO `mob_spell_lists` VALUES
('TRUST_Mihli_Aliapoh',321,1,1,255),    -- cure
('TRUST_Mihli_Aliapoh',321,2,11,255),   -- cure_ii
('TRUST_Mihli_Aliapoh',321,3,21,255),   -- cure_iii
('TRUST_Mihli_Aliapoh',321,4,41,255),   -- cure_iv
('TRUST_Mihli_Aliapoh',321,5,61,255),   -- cure_v
('TRUST_Mihli_Aliapoh',321,6,80,255),   -- cure_vi
('TRUST_Mihli_Aliapoh',321,14,6,255),   -- poisona
('TRUST_Mihli_Aliapoh',321,15,9,255),   -- paralyna
('TRUST_Mihli_Aliapoh',321,16,14,255),  -- blindna
('TRUST_Mihli_Aliapoh',321,17,19,255),  -- silena
('TRUST_Mihli_Aliapoh',321,18,39,255),  -- stona
('TRUST_Mihli_Aliapoh',321,19,34,255),  -- viruna
('TRUST_Mihli_Aliapoh',321,20,29,255),  -- cursna
('TRUST_Mihli_Aliapoh',321,43,7,255),   -- protect
('TRUST_Mihli_Aliapoh',321,44,27,255),  -- protect_ii
('TRUST_Mihli_Aliapoh',321,45,47,255),  -- protect_iii
('TRUST_Mihli_Aliapoh',321,46,63,255),  -- protect_iv
('TRUST_Mihli_Aliapoh',321,47,76,255),  -- protect_v
('TRUST_Mihli_Aliapoh',321,48,17,255),  -- shell
('TRUST_Mihli_Aliapoh',321,49,37,255),  -- shell_ii
('TRUST_Mihli_Aliapoh',321,50,57,255),  -- shell_iii
('TRUST_Mihli_Aliapoh',321,51,68,255),  -- shell_iv
('TRUST_Mihli_Aliapoh',321,52,76,255),  -- shell_v
('TRUST_Mihli_Aliapoh',321,56,13,255),  -- slow
('TRUST_Mihli_Aliapoh',321,58,4,255),   -- paralyze
('TRUST_Mihli_Aliapoh',321,125,7,255),  -- protectra
('TRUST_Mihli_Aliapoh',321,126,27,255), -- protectra_ii
('TRUST_Mihli_Aliapoh',321,127,47,255), -- protectra_iii
('TRUST_Mihli_Aliapoh',321,128,63,255), -- protectra_iv
('TRUST_Mihli_Aliapoh',321,129,75,255), -- protectra_v
('TRUST_Mihli_Aliapoh',321,130,17,255), -- shellra
('TRUST_Mihli_Aliapoh',321,131,37,255), -- shellra_ii
('TRUST_Mihli_Aliapoh',321,132,57,255), -- shellra_iii
('TRUST_Mihli_Aliapoh',321,133,68,255), -- shellra_iv
('TRUST_Mihli_Aliapoh',321,134,75,255); -- shellra_v

-- WHM/WHM, club.
UPDATE `mob_pools` SET
    `mJob` = 3,
    `sJob` = 3,
    `cmbSkill` = 11,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `skill_list_id` = 1024,
    `spellList` = 321
WHERE `poolid` = 5909;
