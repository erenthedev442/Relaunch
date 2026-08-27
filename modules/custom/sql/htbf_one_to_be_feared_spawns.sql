-- Provide independent Omega/Ultima entity pools for HTBF tiers II and III.
-- Tier I occupies 16908382..16908411 (three arenas, ten entities each).
-- IDs 16908413..16908481 belong to Sealion's Den NPCs, including the Iron
-- Gate itself, so tiers II/III live in audited free ranges 16908500..16908559.
-- Remove rows created by the old +30/+60 allocation before rebuilding them.
DELETE FROM `mob_spawn_points`
WHERE `mobid` BETWEEN 16908412 AND 16908471
AND `mobname` IN ('Omega', 'Ultima');

INSERT INTO `mob_spawn_points`
    (`mobid`, `spawnslotid`, `mobname`, `polutils_name`, `groupid`, `minLevel`, `maxLevel`, `pos_x`, `pos_y`, `pos_z`, `pos_rot`)
SELECT `mobid` + 118, `spawnslotid`, `mobname`, `polutils_name`, `groupid`, `minLevel`, `maxLevel`, `pos_x`, `pos_y`, `pos_z`, `pos_rot`
FROM `mob_spawn_points`
WHERE `mobid` BETWEEN 16908382 AND 16908411
ON DUPLICATE KEY UPDATE
    `mobname` = VALUES(`mobname`), `polutils_name` = VALUES(`polutils_name`),
    `groupid` = VALUES(`groupid`), `minLevel` = VALUES(`minLevel`),
    `maxLevel` = VALUES(`maxLevel`), `pos_x` = VALUES(`pos_x`), `pos_y` = VALUES(`pos_y`),
    `pos_z` = VALUES(`pos_z`), `pos_rot` = VALUES(`pos_rot`);

INSERT INTO `mob_spawn_points`
    (`mobid`, `spawnslotid`, `mobname`, `polutils_name`, `groupid`, `minLevel`, `maxLevel`, `pos_x`, `pos_y`, `pos_z`, `pos_rot`)
SELECT `mobid` + 148, `spawnslotid`, `mobname`, `polutils_name`, `groupid`, `minLevel`, `maxLevel`, `pos_x`, `pos_y`, `pos_z`, `pos_rot`
FROM `mob_spawn_points`
WHERE `mobid` BETWEEN 16908382 AND 16908411
ON DUPLICATE KEY UPDATE
    `mobname` = VALUES(`mobname`), `polutils_name` = VALUES(`polutils_name`),
    `groupid` = VALUES(`groupid`), `minLevel` = VALUES(`minLevel`),
    `maxLevel` = VALUES(`maxLevel`), `pos_x` = VALUES(`pos_x`), `pos_y` = VALUES(`pos_y`),
    `pos_z` = VALUES(`pos_z`), `pos_rot` = VALUES(`pos_rot`);
