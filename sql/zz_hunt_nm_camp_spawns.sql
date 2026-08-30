-- Park Despot and Jugner Capricornus on their Hunt Guild camps.
--
-- LoadMOBList skips any mob_spawn_points row at 0,0,0. Retail Despot (lottery)
-- and Jugner Capricornus (Voidwalker) used that placeholder, so they never
-- entered the zone even after hunters_guild_hunt_respawns.sql flipped them to
-- NORMAL 1800s. Steam Cleaner / Brigandish Blade already had real coords.
--
-- zz_ prefix: light deploy applies this. Map restart required after import.

UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0
 WHERE `zoneid` = 130 AND `groupid` = 13;   -- Despot

UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0
 WHERE `zoneid` = 104 AND `groupid` = 76;   -- Capricornus (Jugner)

UPDATE `mob_spawn_points`
   SET `pos_x` = -0.100, `pos_y` = -42.000, `pos_z` = -291.000, `pos_rot` = 114, `spawnslotid` = 0
 WHERE `mobname` = 'Despot'
   AND ((`mobid` >> 12) & 0xFFF) = 130;

UPDATE `mob_spawn_points`
   SET `pos_x` = 240.000, `pos_y` = 0.000, `pos_z` = 40.000, `pos_rot` = 128, `spawnslotid` = 0
 WHERE `mobname` = 'Capricornus'
   AND ((`mobid` >> 12) & 0xFFF) = 104;
