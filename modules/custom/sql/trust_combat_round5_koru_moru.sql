-- Koru-Moru: RDM/WHM buffer. No weaponskills. Does not engage (STANDBACK).
-- Spell list 364 already has retail kit (Haste/Flurry/Refresh II, Phalanx II, etc.).

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1067;
-- Keep empty — no weaponskills.

-- RDM/WHM, stand back (behavior 2 = STANDBACK). No AA/WS.
UPDATE `mob_pools` SET
    `mJob` = 5,
    `sJob` = 3,
    `cmbSkill` = 3,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `behavior` = 2,
    `skill_list_id` = 1067,
    `spellList` = 364
WHERE `poolid` = 5952;
