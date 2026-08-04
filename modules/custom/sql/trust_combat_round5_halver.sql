-- Halver: confirm PLD/WAR polearm kit + MP+30%.
-- Skill list already correct (Raiden Thrust / Penta Thrust / Impulse Drive).

UPDATE `mob_pools` SET
    `mJob` = 7,
    `sJob` = 1,
    `cmbSkill` = 8
WHERE `poolid` = 5972;

-- Retail: Possesses MP+30%.
INSERT INTO `mob_pool_mods` (`poolid`, `modid`, `value`, `is_mob_mod`)
VALUES (5972, 6, 30, 0)
ON DUPLICATE KEY UPDATE `value` = 30, `is_mob_mod` = 0;
