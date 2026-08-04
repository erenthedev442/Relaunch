-- Kuyin Hathdenna: GEO/BRD incorporeal Indi-Precision aura.
-- No spells, no WS, no engage.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1065;
-- Keep empty — no weaponskills.

UPDATE `mob_pools` SET
    `mJob` = 21,
    `sJob` = 10,
    `cmbSkill` = 3,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `behavior` = 2,
    `skill_list_id` = 1065,
    `spellList` = 0
WHERE `poolid` = 5950;
