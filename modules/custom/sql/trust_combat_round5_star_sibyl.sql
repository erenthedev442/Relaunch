-- Star Sibyl: GEO/BRD incorporeal Indi-Acumen aura.
-- No spells, no WS, no engage.

DELETE FROM `mob_skill_lists` WHERE `skill_list_id` = 1050;
-- Keep empty — no weaponskills.

UPDATE `mob_pools` SET
    `mJob` = 21,
    `sJob` = 10,
    `cmbSkill` = 3,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `behavior` = 2,
    `skill_list_id` = 1050,
    `spellList` = 0
WHERE `poolid` = 5935;
