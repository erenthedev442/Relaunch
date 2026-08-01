-- =====================================================================
-- trust_cornelia.sql  --  Trust: Cornelia (Void Keeper capstone)
-- Spell 1003 / pool 6003. Unlocked at Void Keeper when all 120 roster
-- trusts are collected (50M gil).
-- =====================================================================

REPLACE INTO spell_list
    (spellid, name,     jobs, `group`, family, element, zonemisc, validTargets,
     skill, mpCost, castTime, recastTime, message, magicBurstMessage,
     animation, animationTime, AOE, base, multiplier, CE, VE,
     requirements, spell_range, radius, content_tag)
VALUES
    (1003, 'cornelia', '', 8, 0, 7, 0, 1,
     0, 0, 2000, 240000, 0, 0,
     939, 1500, 0, 0, 1.00, 0, 0,
     0, 0, 0, NULL);

REPLACE INTO mob_pools
    (poolid, name,      packet_name, speciesid, modelid,
     mJob, sJob, cmbSkill, cmbDelay, cmbDmgMult,
     behavior, aggro, true_detection, links, mobType, immunity,
     name_prefix, flag, entityFlags, animationsub, hasSpellScript,
     spellList, namevis, roamflag, skill_list_id, resist_id,
     modelSize, modelHitboxSize)
VALUES
    (6003, 'cornelia', 'Cornelia', 246, 3119,
     21, 0, 3, 240, 10,
     0, 0, 0, 0, 0, 0,
     32, 0, 3, 0, 0,
     0, 0, 0, 0, 153,
     1, 12);
