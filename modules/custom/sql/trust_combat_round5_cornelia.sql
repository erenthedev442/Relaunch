-- Cornelia: GEO/BRD incorporeal aura. No spells, no WS, no engage.
-- Pool lives in modules/custom/sql/trusts/trust_cornelia.sql (not base mob_pools).

UPDATE `mob_pools` SET
    `mJob` = 21,
    `sJob` = 10,
    `cmbSkill` = 3,
    `cmbDelay` = 240,
    `cmbDmgMult` = 100,
    `behavior` = 2,
    `skill_list_id` = 0,
    `spellList` = 0
WHERE `poolid` = 6002;
