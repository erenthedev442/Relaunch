-- =====================================================================
-- trust_cornelia.sql  --  Trust: Cornelia (Void Keeper capstone)
-- Spell 1002 / pool 6002. CLIENT spell ID 1002 = "Cornelia".
-- Look 0x00002F0C = model 3119 (same encoding as Monberaux 0x0000300C).
-- Do NOT use MODEL_EQUIPPED (size=1) looks or setModelId alone — trusts
-- with size=1 ignore look.modelid in the entity packet.
-- =====================================================================

REPLACE INTO spell_list
    (spellid, name,     jobs, `group`, family, element, zonemisc, validTargets,
     skill, mpCost, castTime, recastTime, message, magicBurstMessage,
     animation, animationTime, AOE, base, multiplier, CE, VE,
     requirements, spell_range, radius, content_tag)
VALUES
    (1002, 'cornelia', 0x01010101010101010101010101010101010101010101, 8, 0, 7, 0, 1,
     0, 0, 2000, 240000, 0, 0,
     939, 1500, 0, 0, 1.00, 0, 0,
     0, 0, 0, NULL);

-- Clear old wrong slot if previously applied as 1003/6003.
DELETE FROM spell_list WHERE spellid = 1003 AND name = 'cornelia';
DELETE FROM mob_pools WHERE poolid = 6003 AND name = 'cornelia';

REPLACE INTO mob_pools
    (poolid, name,      packet_name, speciesid, modelid,
     mJob, sJob, cmbSkill, cmbDelay, cmbDmgMult,
     behavior, aggro, true_detection, links, mobType, immunity,
     name_prefix, flag, entityFlags, animationsub, hasSpellScript,
     spellList, namevis, roamflag, skill_list_id, resist_id,
     modelSize, modelHitboxSize)
VALUES
    -- model 3119 = 0x0C2F LE -> bytes 2F 0C (trust-era size=0 look, like Monberaux).
    (6002, 'cornelia', 'Cornelia', 293, UNHEX('00002F0C00000000000000000000000000000000'),
     21, 10, 3, 240, 100,
     2, 0, 0, 0, 0, 0,
     32, 0, 3, 0, 0,
     0, 0, 0, 0, 145,
     1, 12);
