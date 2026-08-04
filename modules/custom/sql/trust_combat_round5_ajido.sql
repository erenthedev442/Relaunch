-- Ajido-Marujido: BLM/RDM palm-blast nuker. No TP moves.
-- Trim Cure V/VI (retail Cure I–IV only). Affirm empty skill list + weak H2H AA.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1019;

-- Retail spell kit: Cure I–IV, Slow, Paralyze, Dispel, nukes I–V.
DELETE FROM `mob_spell_lists` WHERE `spell_list_id` = 316;

INSERT INTO `mob_spell_lists` VALUES
('TRUST_Ajido-Marujido',316,1,1,255),    -- cure
('TRUST_Ajido-Marujido',316,2,11,255),   -- cure_ii
('TRUST_Ajido-Marujido',316,3,21,255),   -- cure_iii
('TRUST_Ajido-Marujido',316,4,41,255),   -- cure_iv
('TRUST_Ajido-Marujido',316,56,26,255),  -- slow
('TRUST_Ajido-Marujido',316,58,12,255),  -- paralyze
('TRUST_Ajido-Marujido',316,144,13,255), -- fire
('TRUST_Ajido-Marujido',316,145,38,255), -- fire_ii
('TRUST_Ajido-Marujido',316,146,62,255), -- fire_iii
('TRUST_Ajido-Marujido',316,147,73,255), -- fire_iv
('TRUST_Ajido-Marujido',316,148,86,255), -- fire_v
('TRUST_Ajido-Marujido',316,149,17,255), -- blizzard
('TRUST_Ajido-Marujido',316,150,42,255), -- blizzard_ii
('TRUST_Ajido-Marujido',316,151,64,255), -- blizzard_iii
('TRUST_Ajido-Marujido',316,152,74,255), -- blizzard_iv
('TRUST_Ajido-Marujido',316,153,89,255), -- blizzard_v
('TRUST_Ajido-Marujido',316,154,9,255),  -- aero
('TRUST_Ajido-Marujido',316,155,34,255), -- aero_ii
('TRUST_Ajido-Marujido',316,156,59,255), -- aero_iii
('TRUST_Ajido-Marujido',316,157,72,255), -- aero_iv
('TRUST_Ajido-Marujido',316,158,83,255), -- aero_v
('TRUST_Ajido-Marujido',316,159,1,255),  -- stone
('TRUST_Ajido-Marujido',316,160,26,255), -- stone_ii
('TRUST_Ajido-Marujido',316,161,51,255), -- stone_iii
('TRUST_Ajido-Marujido',316,162,68,255), -- stone_iv
('TRUST_Ajido-Marujido',316,163,77,255), -- stone_v
('TRUST_Ajido-Marujido',316,164,21,255), -- thunder
('TRUST_Ajido-Marujido',316,165,46,255), -- thunder_ii
('TRUST_Ajido-Marujido',316,166,66,255), -- thunder_iii
('TRUST_Ajido-Marujido',316,167,75,255), -- thunder_iv
('TRUST_Ajido-Marujido',316,168,92,255), -- thunder_v
('TRUST_Ajido-Marujido',316,169,5,255),  -- water
('TRUST_Ajido-Marujido',316,170,30,255), -- water_ii
('TRUST_Ajido-Marujido',316,171,55,255), -- water_iii
('TRUST_Ajido-Marujido',316,172,70,255), -- water_iv
('TRUST_Ajido-Marujido',316,173,80,255), -- water_v
('TRUST_Ajido-Marujido',316,260,64,255); -- dispel

-- BLM/RDM, weak H2H palm blasts (no WS). NO_MOVE + AI in Lua.
UPDATE `mob_pools` SET
    `mJob` = 4,
    `sJob` = 5,
    `cmbSkill` = 1,
    `cmbDelay` = 400,
    `cmbDmgMult` = 40,
    `skill_list_id` = 1019,
    `spell_list_id` = 316
WHERE `poolid` = 5904;
