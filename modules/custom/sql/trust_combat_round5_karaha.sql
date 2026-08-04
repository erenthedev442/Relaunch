-- Karaha-Baruha: WHM/SMN C-tier healer. Restore Howling Moon / Lunar Bay
-- (stripped in round3). Affirm staff WS anims + Barelementra / -na spell kit.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1051;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Karaha-Baruha',1051,183),  -- Spirit Taker (no SC; MP return)
('TRUST_Karaha-Baruha',1051,179),  -- Starburst
('TRUST_Karaha-Baruha',1051,180),  -- Sunburst
('TRUST_Karaha-Baruha',1051,3337), -- Lunar Bay (Gravitation / Transfixion)
('TRUST_Karaha-Baruha',1051,3336); -- Howling Moon AoE (HIGHEST dump)

-- Staff WS anims / SC props.
UPDATE `mob_skills` SET
    `mob_anim_id` = 143,
    `mob_skill_name` = 'spirit_taker',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 4,
    `primary_sc` = 0,
    `secondary_sc` = 0,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 183;

UPDATE `mob_skills` SET
    `mob_anim_id` = 139,
    `mob_skill_name` = 'starburst',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 4,
    `primary_sc` = 2,
    `secondary_sc` = 5,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 179;

UPDATE `mob_skills` SET
    `mob_anim_id` = 140,
    `mob_skill_name` = 'sunburst',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 4,
    `primary_sc` = 2,
    `secondary_sc` = 5,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 180;

-- Trust Howling Moon: AoE dark, Gravitation / Compression.
UPDATE `mob_skills` SET
    `mob_anim_id` = 314,
    `mob_skill_name` = 'howling_moon',
    `mob_skill_aoe` = 1,
    `mob_skill_aoe_radius` = 10.0,
    `mob_skill_distance` = 10.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 1500,
    `mob_valid_targets` = 4,
    `primary_sc` = 9,
    `secondary_sc` = 2,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3336;

-- Lunar Bay: single-target dark, Gravitation / Transfixion.
UPDATE `mob_skills` SET
    `mob_anim_id` = 313,
    `mob_skill_name` = 'lunar_bay',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 10.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 1500,
    `mob_valid_targets` = 4,
    `primary_sc` = 9,
    `secondary_sc` = 1,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 3337;

-- Full retail spell kit.
DELETE FROM `mob_spell_lists` WHERE `spell_list_id` = 348;

INSERT INTO `mob_spell_lists` VALUES
('TRUST_Karaha-Baruha',348,1,1,255),    -- cure
('TRUST_Karaha-Baruha',348,2,11,255),   -- cure_ii
('TRUST_Karaha-Baruha',348,3,21,255),   -- cure_iii
('TRUST_Karaha-Baruha',348,4,41,255),   -- cure_iv
('TRUST_Karaha-Baruha',348,5,61,255),   -- cure_v
('TRUST_Karaha-Baruha',348,6,80,255),   -- cure_vi
('TRUST_Karaha-Baruha',348,14,6,255),   -- poisona
('TRUST_Karaha-Baruha',348,15,9,255),   -- paralyna
('TRUST_Karaha-Baruha',348,16,14,255),  -- blindna
('TRUST_Karaha-Baruha',348,17,19,255),  -- silena
('TRUST_Karaha-Baruha',348,18,39,255),  -- stona
('TRUST_Karaha-Baruha',348,19,34,255),  -- viruna
('TRUST_Karaha-Baruha',348,20,29,255),  -- cursna
('TRUST_Karaha-Baruha',348,43,7,255),   -- protect
('TRUST_Karaha-Baruha',348,44,27,255),  -- protect_ii
('TRUST_Karaha-Baruha',348,45,47,255),  -- protect_iii
('TRUST_Karaha-Baruha',348,46,63,255),  -- protect_iv
('TRUST_Karaha-Baruha',348,47,75,255),  -- protect_v
('TRUST_Karaha-Baruha',348,48,17,255),  -- shell
('TRUST_Karaha-Baruha',348,49,37,255),  -- shell_ii
('TRUST_Karaha-Baruha',348,50,57,255),  -- shell_iii
('TRUST_Karaha-Baruha',348,51,68,255),  -- shell_iv
('TRUST_Karaha-Baruha',348,52,75,255),  -- shell_v
('TRUST_Karaha-Baruha',348,57,40,255),  -- haste
('TRUST_Karaha-Baruha',348,66,17,255),  -- barfira
('TRUST_Karaha-Baruha',348,67,21,255),  -- barblizzara
('TRUST_Karaha-Baruha',348,68,13,255),  -- baraera
('TRUST_Karaha-Baruha',348,69,5,255),   -- barstonra
('TRUST_Karaha-Baruha',348,70,25,255),  -- barthundra
('TRUST_Karaha-Baruha',348,71,9,255),   -- barwatera
('TRUST_Karaha-Baruha',348,125,7,255),  -- protectra
('TRUST_Karaha-Baruha',348,126,27,255), -- protectra_ii
('TRUST_Karaha-Baruha',348,127,47,255), -- protectra_iii
('TRUST_Karaha-Baruha',348,128,63,255), -- protectra_iv
('TRUST_Karaha-Baruha',348,129,75,255), -- protectra_v
('TRUST_Karaha-Baruha',348,130,17,255), -- shellra
('TRUST_Karaha-Baruha',348,131,37,255), -- shellra_ii
('TRUST_Karaha-Baruha',348,132,57,255), -- shellra_iii
('TRUST_Karaha-Baruha',348,133,68,255), -- shellra_iv
('TRUST_Karaha-Baruha',348,134,75,255), -- shellra_v
('TRUST_Karaha-Baruha',348,143,32,255); -- erase

-- WHM/SMN, staff.
UPDATE `mob_pools` SET
    `mJob` = 3,
    `sJob` = 15,
    `cmbSkill` = 12,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `skill_list_id` = 1051,
    `spellList` = 348
WHERE `poolid` = 5936;
