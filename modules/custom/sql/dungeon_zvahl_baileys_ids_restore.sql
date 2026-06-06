-- ============================================================
-- dungeon_zvahl_baileys_ids_restore.sql
--
-- ONE-TIME RECOVERY SCRIPT for an over-aggressive scrub.
--
-- The original dungeon_zvahl_baileys_scrub.sql deleted ALL
-- mob_groups + mob_spawn_points for zone 161. That was too
-- broad — the zone's vanilla IDs.lua file references 9
-- BCNM/Garrison/quest mobs by name (GetFirstID lookups), and
-- those lookups return nil after the scrub, spamming the map
-- server log with errors like:
--   [error] GetFirstID(Marquis_Sabnock) in zone Castle_Zvahl_Baileys:
--           Returning nil
--
-- The fix: re-insert the 9 rows. All of these are SCRIPTED
-- (spawntype=128) or LOTTERY (spawntype=32) with respawntime=0,
-- meaning they NEVER actually spawn in normal play — they only
-- exist so the engine has a valid id when IDs.lua looks them up.
-- Restoring them costs us nothing dungeon-side (no visible
-- patrols come back) but silences the log noise.
--
-- The original scrub SQL has been updated to NOT delete these
-- 9 group/spawn rows going forward, so this file is a ONE-TIME
-- recovery — you don't need to keep running it.
--
-- To apply:
--   mysql -u root -p your_db_name < modules/custom/sql/dungeon_zvahl_baileys_ids_restore.sql
--
-- Idempotent: INSERT IGNORE skips rows that already exist.
-- ============================================================

-- Restore the 9 mob_groups rows (extracted from vanilla
-- sql/mob_groups.sql for zone 161).
INSERT IGNORE INTO `mob_groups` VALUES
  ( 7, 2414, 161, 'Likho',                0, 128, 1522, 7000, 0, 0, 'WOTG'),
  (37, 5763, 161, 'Marquis_Sabnock',      0,  32, 3047, 9500, 0, 0, 'WOTG'),
  (42, 2568, 161, 'Marquis_Allocen',      0, 128, 1622, 4800, 0, 0, NULL),
  (44, 2569, 161, 'Marquis_Amon',         0, 128, 1623, 4200, 0, 0, NULL),
  (45, 1134, 161, 'Duke_Haborym',         0, 128,  716, 4500, 0, 0, NULL),
  (46, 1786, 161, 'Grand_Duke_Batym',     0, 128, 1213, 4100, 0, 0, NULL),
  (48,  917, 161, 'Dark_Spark',           0, 128,    0, 8600, 0, 0, NULL),
  (49, 2664, 161, 'Mimic',                0, 128, 1683,    0, 0, 0, NULL),
  (50, 2571, 161, 'Marquis_Andrealphus',  0, 128,    0,    0, 0, 0, NULL);

-- Restore the 9 mob_spawn_points rows (extracted from vanilla
-- sql/mob_spawn_points.sql, mobid range 17436672..17440767).
INSERT IGNORE INTO `mob_spawn_points` VALUES
  (17436714, 0, 'Likho',               'Likho',                7, 67, 68,  141.130, -24.030,  60.870,  60),
  (17436881, 0, 'Marquis_Sabnock',     'Marquis Sabnock',     37, 73, 75,   70.800,  -8.000,-119.500,  60),
  (17436913, 0, 'Marquis_Allocen',     'Marquis Allocen',     42, 76, 76,  -44.116,  -4.496,  37.549, 100),
  (17436918, 0, 'Marquis_Amon',        'Marquis Amon',        44, 76, 76,  -30.715,  -4.500, -20.455,  29),
  (17436923, 0, 'Duke_Haborym',        'Duke Haborym',        45, 76, 76,  -93.769,  -4.499,  34.776,   6),
  (17436927, 0, 'Grand_Duke_Batym',    'Grand Duke Batym',    46, 76, 76,  -78.000,  -4.000, -15.000, 127),
  (17436964, 0, 'Dark_Spark',          'Dark Spark',          48, 55, 55,   62.000, -24.000,  19.000,  10),
  (17436965, 0, 'Mimic',               'Mimic',               49, 60, 60,  189.783,  20.290,  20.761,  77),
  (17436966, 0, 'Marquis_Andrealphus', 'Marquis Andrealphus', 50, 76, 76,  -13.818, -24.539,  20.325, 245);
