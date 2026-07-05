REPLACE INTO spell_list
    (spellid, name, jobs, `group`, family, element, zonemisc, validTargets,
     skill, mpCost, castTime, recastTime, message, magicBurstMessage,
     animation, animationTime, AOE, base, multiplier, CE, VE,
     requirements, spell_range, radius, content_tag)
VALUES
    (930, 'locke', '', 8, 0, 7, 0, 1,
     0, 0, 2000, 240000, 0, 0,
     939, 1500, 0, 0, 1.00, 0, 0,
     0, 0, 0, NULL);

REPLACE INTO mob_skill_lists
    (skill_list_name, skill_list_id, mob_skill_id)
VALUES
    ('locke_mandastab', 5930, 27),
    ('locke_rudra', 5930, 31);

REPLACE INTO mob_pools
    (poolid, name, packet_name, speciesid, modelid,
     mJob, sJob, cmbSkill, cmbDelay, cmbDmgMult,
     behavior, aggro, true_detection, links, mobType, immunity,
     name_prefix, flag, entityFlags, animationsub, hasSpellScript,
     spellList, namevis, roamflag, skill_list_id, resist_id,
     modelSize, modelHitboxSize)
VALUES
    (5930, 'locke', 'Locke', 246, UNHEX('01000907D111D121D131D141D1510F620F720000'),
     6, 19, 2, 240, 250,
     0, 0, 0, 0, 0, 0,
     32, 0, 3, 0, 0,
     0, 0, 0, 5930, 153,
     1, 12);