-- ============================================================
-- hunting_league_gm_home_mobs.sql
-- Custom mob_groups entries for the Hunting League system.
--
-- NMs are spawned dynamically via insertDynamicEntity(objtype=MOB).
-- mob_spawn_points are NOT used — this file only supplies the
-- mob_groups rows that InstantiateDynamicMob reads for stats/pools.
--
-- mob_groups columns:
--   groupid, poolid, zoneid, name, respawntime, spawntype,
--   dropid, HP, MP, allegiance, content_tag
--
-- groupids 11355–11369 are reserved for this system.
-- poolids reference existing mob_pools entries (NM source stats).
--
-- Safe to re-apply (DELETE then INSERT).
--
-- To apply:
--   mysql -u root -p your_db_name < modules/custom/sql/hunting_league_gm_home_mobs.sql
-- ============================================================

-- Clean up any static spawn points left over from the previous approach.
-- These are no longer used and would conflict with dynamic spawning.
DELETE FROM `mob_spawn_points` WHERE `groupid` BETWEEN 11355 AND 11369;

-- Idempotent mob_groups — safe to re-run.
-- IMPORTANT: zoneid filter is REQUIRED. The same groupid range (11355-11369)
-- is also registered at zoneid=292 (Reisenjima Henge) by hunting_league_mobs.sql
-- for the Hunting League system. Without this filter, re-running either SQL
-- nukes the OTHER zone's rows and that zone's mobs render as the engine's
-- fallback model (looks like an Orc to players).
DELETE FROM `mob_groups` WHERE `groupid` BETWEEN 11355 AND 11369 AND `zoneid` = 210;

-- Tier 1 — Rank I: Initiate
INSERT INTO `mob_groups` VALUES (11355, 2384, 210, 'Leaping_Lizzy',   0, 128, 103,  0,      0,      0, NULL);
INSERT INTO `mob_groups` VALUES (11356, 4124, 210, 'Valkurm_Emperor', 0, 128, 571,  0,      0,      0, NULL);
INSERT INTO `mob_groups` VALUES (11357, 3947, 210, 'Tom_Tit_Tat',     0, 128, 2426, 0,      0,      0, NULL);

-- Tier 2 — Rank II: Hunter
INSERT INTO `mob_groups` VALUES (11358, 3376, 210, 'Roc',             0, 128, 1990, 0,      0,      0, NULL);
INSERT INTO `mob_groups` VALUES (11359, 498,  210, 'Bomb_Queen',      0, 128, 334,  47000,  0,      0, NULL);
INSERT INTO `mob_groups` VALUES (11360, 206,  210, 'Aquarius',        0, 128, 100,  0,      0,      0, NULL);

-- Tier 3 — Rank III: Elite
INSERT INTO `mob_groups` VALUES (11361, 3549, 210, 'Serket',          0, 128, 99,   0,      0,      0, NULL);
INSERT INTO `mob_groups` VALUES (11362, 4261, 210, 'Vrtra',           0, 128, 2592, 100000, 100000, 0, NULL);
INSERT INTO `mob_groups` VALUES (11363, 3630, 210, 'Simurgh',         0, 128, 1990, 0,      0,      0, NULL);

-- Tier 4 — Rank IV: Champion
INSERT INTO `mob_groups` VALUES (11364, 2840, 210, 'Nidhogg',         0, 128, 1781, 60000,  0,      0, NULL);
INSERT INTO `mob_groups` VALUES (11365, 2255, 210, 'King_Behemoth',   0, 128, 1450, 75000,  0,      0, NULL);
INSERT INTO `mob_groups` VALUES (11366, 2265, 210, 'Kirin',           0, 128, 2819, 60000,  60000,  0, NULL);

-- Tier 5 — Rank V: Legend
INSERT INTO `mob_groups` VALUES (11367, 21,   210, 'Absolute_Virtue',    0, 128, 3,    66000,  0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11368, 7175, 210, 'Pandemonium_Warden', 0, 128, 1977, 147000, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11369, 3604, 210, 'Shinryu',            0, 128, 2238, 0,      0, 0, NULL);
