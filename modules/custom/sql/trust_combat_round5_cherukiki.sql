-- Cherukiki: WHM/BLM C-tier regen healer. No WS (list stays empty).
-- Add Protect/Shell I–V (retail Protect/ra + Shell/ra). Regen I–IV already present.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1031;

-- Full retail spell kit: Cure I–VI, Protect/ra, Shell/ra, Regen I–IV, Haste, Slow/Para/Silence.
DELETE FROM `mob_spell_lists` WHERE `spell_list_id` = 328;

INSERT INTO `mob_spell_lists` VALUES
('TRUST_Cherukiki',328,1,1,255),    -- cure
('TRUST_Cherukiki',328,2,11,255),   -- cure_ii
('TRUST_Cherukiki',328,3,21,255),   -- cure_iii
('TRUST_Cherukiki',328,4,41,255),   -- cure_iv
('TRUST_Cherukiki',328,5,61,255),   -- cure_v
('TRUST_Cherukiki',328,6,80,255),   -- cure_vi
('TRUST_Cherukiki',328,43,7,255),   -- protect
('TRUST_Cherukiki',328,44,27,255),  -- protect_ii
('TRUST_Cherukiki',328,45,47,255),  -- protect_iii
('TRUST_Cherukiki',328,46,63,255),  -- protect_iv
('TRUST_Cherukiki',328,47,76,255),  -- protect_v
('TRUST_Cherukiki',328,48,17,255),  -- shell
('TRUST_Cherukiki',328,49,37,255),  -- shell_ii
('TRUST_Cherukiki',328,50,57,255),  -- shell_iii
('TRUST_Cherukiki',328,51,68,255),  -- shell_iv
('TRUST_Cherukiki',328,52,76,255),  -- shell_v
('TRUST_Cherukiki',328,56,13,255),  -- slow
('TRUST_Cherukiki',328,57,40,255),  -- haste
('TRUST_Cherukiki',328,58,4,255),   -- paralyze
('TRUST_Cherukiki',328,59,4,255),   -- silence
('TRUST_Cherukiki',328,108,21,255), -- regen
('TRUST_Cherukiki',328,110,44,255), -- regen_ii
('TRUST_Cherukiki',328,111,66,255), -- regen_iii
('TRUST_Cherukiki',328,125,7,255),  -- protectra
('TRUST_Cherukiki',328,126,27,255), -- protectra_ii
('TRUST_Cherukiki',328,127,47,255), -- protectra_iii
('TRUST_Cherukiki',328,128,63,255), -- protectra_iv
('TRUST_Cherukiki',328,129,75,255), -- protectra_v
('TRUST_Cherukiki',328,130,17,255), -- shellra
('TRUST_Cherukiki',328,131,37,255), -- shellra_ii
('TRUST_Cherukiki',328,132,57,255), -- shellra_iii
('TRUST_Cherukiki',328,133,68,255), -- shellra_iv
('TRUST_Cherukiki',328,134,75,255), -- shellra_v
('TRUST_Cherukiki',328,477,86,255); -- regen_iv

-- WHM/BLM. No WS / no engage.
UPDATE `mob_pools` SET
    `mJob` = 3,
    `sJob` = 4,
    `cmbSkill` = 11,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `skill_list_id` = 1031,
    `spellList` = 328
WHERE `poolid` = 5916;
