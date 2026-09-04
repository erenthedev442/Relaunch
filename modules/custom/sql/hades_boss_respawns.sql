-- ============================================================
-- hades_boss_respawns.sql
--
-- Hades daily "world boss" NMs: flip the open-world copy of each
-- from lottery / scripted / 21h windows to NORMAL 30-minute (1800s)
-- timed spawn. Lua in hades_boss_respawn.lua stomps leftover
-- setRespawnTime calls in the mob files and force-spawns a single
-- copy on zone init so they are actually up.
--
-- Scoped to the home-zone (zoneid, groupid) only. Nyzul / holding
-- / Hunting League / Reforge copies are left alone.
--
-- Intentionally omitted (live-content collisions):
--   Serket       -- custom_HNM_system 6-8h window
--   King Arthro  -- custom_HNM_system 8-10h + knight crabs + Affinity copy
--   Padfoot      -- 5-sheep "which one is real" gimmick
--
-- Deploy applies modules/custom/sql/*.sql. Idempotent.
-- ============================================================

UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 100 AND `groupid` = 25; -- Jaggedy-Eared Jack (West Ronfaure)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 100 AND `groupid` = 23; -- Fungus Beetle      (West Ronfaure)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 106 AND `groupid` = 16; -- Stinging Sophie    (North Gustaberg)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 107 AND `groupid` = 29; -- Leaping Lizzy      (South Gustaberg)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 107 AND `groupid` = 17; -- Carnero            (South Gustaberg)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 101 AND `groupid` = 26; -- Bigmouth Billy     (East Ronfaure)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 115 AND `groupid` = 25; -- Tom Tit Tat        (West Sarutabaruta)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 103 AND `groupid` = 30; -- Valkurm Emperor    (Valkurm Dunes)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 120 AND `groupid` = 34; -- Deadly Dodo        (Sauromugue Champaign)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 110 AND `groupid` = 39; -- Drooling Daisy     (Rolanberry Fields)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 102 AND `groupid` = 42; -- Bloodtear Baldurf  (La Theine Plateau)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 200 AND `groupid` = 14; -- Skewer Sam         (Garlaige Citadel)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 102 AND `groupid` = 40; -- Tumbling Truffle   (La Theine Plateau)
UPDATE `mob_groups` SET `respawntime` = 1800, `spawntype` = 0 WHERE `zoneid` = 205 AND `groupid` = 25; -- Bomb Queen         (Ifrit's Cauldron)
