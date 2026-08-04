-- =====================================================================
-- trust_fujito_pd.sql  --  Trust: Fujito-PD (implemented, NOT grantable yet)
-- Spell 1020 / pool 6020 / skill list 1135.
-- Locked via xi.trust.DISABLED_SPELL until an unlock path is chosen.
-- APPLY: mysql ... < modules/custom/sql/trusts/trust_fujito_pd.sql
-- Then map restart (trustutils loads pools at boot).
-- =====================================================================

REPLACE INTO spell_list
    (spellid, name,        jobs, `group`, family, element, zonemisc, validTargets,
     skill, mpCost, castTime, recastTime, message, magicBurstMessage,
     animation, animationTime, AOE, base, multiplier, CE, VE,
     requirements, spell_range, radius, content_tag)
VALUES
    (1020, 'fujito_pd', 0x01010101010101010101010101010101010101010101, 8, 0, 7, 0, 1,
     0, 0, 2000, 240000, 0, 0,
     939, 1500, 0, 0, 1.00, 0, 0,
     0, 0, 0, NULL);

DELETE FROM mob_skill_lists WHERE skill_list_id = 1135;
INSERT INTO mob_skill_lists (skill_list_name, skill_list_id, mob_skill_id) VALUES
('TRUST_Fujito_PD', 1135, 83),  -- Armor Break
('TRUST_Fujito_PD', 1135, 82),  -- Sturmwind
('TRUST_Fujito_PD', 1135, 84),  -- Keen Edge
('TRUST_Fujito_PD', 1135, 86),  -- Raging Rush
('TRUST_Fujito_PD', 1135, 87),  -- Full Break
('TRUST_Fujito_PD', 1135, 88),  -- Steel Cyclone
('TRUST_Fujito_PD', 1135, 93),  -- Upheaval
('TRUST_Fujito_PD', 1135, 92),  -- Ukko's Fury
('TRUST_Fujito_PD', 1135, 90),  -- King's Justice
('TRUST_Fujito_PD', 1135, 94);  -- Disaster (preferred opener; highest ID → HIGHEST)

REPLACE INTO mob_pools
    (poolid, name,        packet_name, speciesid, modelid,
     mJob, sJob, cmbSkill, cmbDelay, cmbDmgMult,
     behavior, aggro, true_detection, links, mobType, immunity,
     name_prefix, flag, entityFlags, animationsub, hasSpellScript,
     spellList, namevis, roamflag, skill_list_id, resist_id,
     modelSize, modelHitboxSize)
VALUES
    -- Placeholder Tarutaru look (model 3124 = 0x0C34). Swap when a DAT capture is available.
    (6020, 'fujito_pd', 'Fujito-PD', 297, UNHEX('0000340C00000000000000000000000000000000'),
     1, 19, 6, 240, 100,
     0, 0, 0, 0, 0, 0,
     32, 0, 3, 0, 0,
     0, 0, 0, 1135, 153,
     1, 12);
