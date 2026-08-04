-- Ferreous Coffin: WHM/WAR C-tier healer. Randgrith only (Light/Fragmentation).
-- Add Poisona to -na kit. Affirm anim / SC props / pool jobs.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1059;

INSERT INTO `mob_skill_lists` VALUES
('TRUST_Ferreous_Coffin',1059,170); -- Randgrith

-- Club Randgrith: anim 86, Light / Fragmentation, single-target.
UPDATE `mob_skills` SET
    `mob_anim_id` = 86,
    `mob_skill_name` = 'randgrith',
    `mob_skill_aoe` = 0,
    `mob_skill_distance` = 7.0,
    `mob_anim_time` = 2000,
    `mob_prepare_time` = 0,
    `mob_valid_targets` = 4,
    `primary_sc` = 13,
    `secondary_sc` = 12,
    `tertiary_sc` = 0
WHERE `mob_skill_id` = 170;

-- Full retail spell kit: Cure I–VI, Raise I–III, -na (incl. Poisona), Haste, Erase.
DELETE FROM `mob_spell_lists` WHERE `spell_list_id` = 356;

INSERT INTO `mob_spell_lists` VALUES
('TRUST_Ferreous_Coffin',356,1,1,255),    -- cure
('TRUST_Ferreous_Coffin',356,2,11,255),   -- cure_ii
('TRUST_Ferreous_Coffin',356,3,21,255),   -- cure_iii
('TRUST_Ferreous_Coffin',356,4,41,255),   -- cure_iv
('TRUST_Ferreous_Coffin',356,5,61,255),   -- cure_v
('TRUST_Ferreous_Coffin',356,6,80,255),   -- cure_vi
('TRUST_Ferreous_Coffin',356,12,25,255),  -- raise
('TRUST_Ferreous_Coffin',356,13,56,255),  -- raise_ii
('TRUST_Ferreous_Coffin',356,14,6,255),   -- poisona
('TRUST_Ferreous_Coffin',356,15,9,255),   -- paralyna
('TRUST_Ferreous_Coffin',356,16,14,255),  -- blindna
('TRUST_Ferreous_Coffin',356,17,19,255),  -- silena
('TRUST_Ferreous_Coffin',356,18,39,255),  -- stona
('TRUST_Ferreous_Coffin',356,19,34,255),  -- viruna
('TRUST_Ferreous_Coffin',356,20,29,255),  -- cursna
('TRUST_Ferreous_Coffin',356,57,40,255),  -- haste
('TRUST_Ferreous_Coffin',356,140,70,255), -- raise_iii
('TRUST_Ferreous_Coffin',356,143,32,255); -- erase

-- WHM/WAR, club. HP-10% / MP+35% remain in mob_pool_mods.
UPDATE `mob_pools` SET
    `mJob` = 3,
    `sJob` = 1,
    `cmbSkill` = 11,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `skill_list_id` = 1059,
    `spellList` = 356
WHERE `poolid` = 5944;
