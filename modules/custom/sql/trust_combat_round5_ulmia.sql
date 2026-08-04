-- Ulmia: BRD/BRD buffer CORE. No WS. Does not engage (STANDBACK).
-- Add Hunter's Prelude; spell list otherwise retail-complete.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1029;
-- Keep empty — no weaponskills.

DELETE FROM `mob_spell_lists`
WHERE `spell_list_id` = 326 AND `spell_id` = 401;

INSERT INTO `mob_spell_lists` VALUES
('TRUST_Ulmia',326,401,31,255); -- hunters_prelude

-- BRD/BRD, stand back. No AA/WS.
UPDATE `mob_pools` SET
    `mJob` = 10,
    `sJob` = 10,
    `cmbSkill` = 3,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `behavior` = 2,
    `skill_list_id` = 1029,
    `spellList` = 326
WHERE `poolid` = 5914;
