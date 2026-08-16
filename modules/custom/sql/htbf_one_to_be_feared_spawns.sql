-- Provide independent Omega/Ultima entity pools for HTBF tiers II and III.
-- Tier I occupies 16908382..16908411 (three arenas, ten entities each).
-- The registrar uses a 30-ID stride, so clone those verified rows into the
-- two missing ranges instead of falling through to unrelated/empty mob IDs.
INSERT INTO `mob_spawn_points`
    (`mobid`, `spawnslotid`, `mobname`, `polutils_name`, `groupid`, `minLevel`, `maxLevel`, `pos_x`, `pos_y`, `pos_z`, `pos_rot`)
SELECT `mobid` + 30, `spawnslotid`, `mobname`, `polutils_name`, `groupid`, `minLevel`, `maxLevel`, `pos_x`, `pos_y`, `pos_z`, `pos_rot`
FROM `mob_spawn_points`
WHERE `mobid` BETWEEN 16908382 AND 16908411
ON DUPLICATE KEY UPDATE
    `mobname` = VALUES(`mobname`), `polutils_name` = VALUES(`polutils_name`),
    `groupid` = VALUES(`groupid`), `minLevel` = VALUES(`minLevel`),
    `maxLevel` = VALUES(`maxLevel`), `pos_x` = VALUES(`pos_x`), `pos_y` = VALUES(`pos_y`),
    `pos_z` = VALUES(`pos_z`), `pos_rot` = VALUES(`pos_rot`);

INSERT INTO `mob_spawn_points`
    (`mobid`, `spawnslotid`, `mobname`, `polutils_name`, `groupid`, `minLevel`, `maxLevel`, `pos_x`, `pos_y`, `pos_z`, `pos_rot`)
SELECT `mobid` + 60, `spawnslotid`, `mobname`, `polutils_name`, `groupid`, `minLevel`, `maxLevel`, `pos_x`, `pos_y`, `pos_z`, `pos_rot`
FROM `mob_spawn_points`
WHERE `mobid` BETWEEN 16908382 AND 16908411
ON DUPLICATE KEY UPDATE
    `mobname` = VALUES(`mobname`), `polutils_name` = VALUES(`polutils_name`),
    `groupid` = VALUES(`groupid`), `minLevel` = VALUES(`minLevel`),
    `maxLevel` = VALUES(`maxLevel`), `pos_x` = VALUES(`pos_x`), `pos_y` = VALUES(`pos_y`),
    `pos_z` = VALUES(`pos_z`), `pos_rot` = VALUES(`pos_rot`);
