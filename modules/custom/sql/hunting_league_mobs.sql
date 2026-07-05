-- ============================================================
-- hunting_league_mobs.sql
-- Custom mob_groups entries for the Hunting League system.
-- Hunt zone: Escha - Zi'Tah (zone 288)
--
-- NMs are spawned dynamically via insertDynamicEntity(objtype=MOB).
-- mob_spawn_points are NOT used — only mob_groups is required for
-- stat/pool lookup by InstantiateDynamicMob.
--
-- mob_groups columns:
--   groupid, poolid, zoneid, name, respawntime, spawntype,
--   dropid, HP, MP, allegiance, content_tag
--
-- groupids 11355–11369 are reserved for this system.
--
-- Safe to re-apply (DELETE then INSERT).
--
-- To apply:
--   mysql -u root -p your_db_name < modules/custom/sql/hunting_league_mobs.sql
-- ============================================================

-- Remove any leftover static spawn points from prior approaches.
DELETE FROM `mob_spawn_points` WHERE `groupid` BETWEEN 11355 AND 11369;

-- Dedicate Escha - Zi'Tah (zone 288) to the Hunting League: clear every native
-- mob spawn point in the zone so only the dynamic HL NMs live here. This clear
-- previously lived in the one-time hunting_league_escha_migration.sql (now moved
-- to sql-archive/); it is idempotent and belongs with the canonical definition.
--   Scope by the zone encoded in the mobid: (mobid >> 12) & 0xFFF = zoneid.
--   DO NOT join mob_spawn_points to mob_groups on groupid alone -- `groupid` is
--   REUSED across zones, so a groupid join deleted mob_spawn_points server-wide
--   and gutted the table 82,974 -> 11,879 rows on 2026-06-15. HL NMs are
--   pure-dynamic (no spawn points), so this never touches them.
DELETE FROM `mob_spawn_points` WHERE ((`mobid` >> 12) & 0xFFF) = 288;

-- Idempotent mob_groups — safe to re-run.
-- IMPORTANT: zoneid filter is REQUIRED. The same groupid range (11355-11369)
-- is also registered at zoneid=210 (GM Home) by hunting_league_gm_home_mobs.sql
-- for the Game Master system. Without this filter, re-running either SQL
-- nukes the OTHER zone's rows and that zone's mobs render as the engine's
-- fallback model (looks like an Orc to players).
DELETE FROM `mob_groups` WHERE `groupid` BETWEEN 11355 AND 11369 AND `zoneid` = 288;

-- Tier 1 — Rank I: Initiate
INSERT INTO `mob_groups` VALUES (11355, 2384, 288, 'Leaping_Lizzy',   0, 128, 103,  0,      0,      0, NULL);
INSERT INTO `mob_groups` VALUES (11356, 4124, 288, 'Valkurm_Emperor', 0, 128, 571,  0,      0,      0, NULL);
INSERT INTO `mob_groups` VALUES (11357, 3947, 288, 'Tom_Tit_Tat',     0, 128, 2426, 0,      0,      0, NULL);

-- Tier 2 — Rank II: Hunter
INSERT INTO `mob_groups` VALUES (11358, 3376, 288, 'Roc',             0, 128, 1990, 0,      0,      0, NULL);
INSERT INTO `mob_groups` VALUES (11359, 498,  288, 'Bomb_Queen',      0, 128, 334,  47000,  0,      0, NULL);
INSERT INTO `mob_groups` VALUES (11360, 206,  288, 'Aquarius',        0, 128, 100,  0,      0,      0, NULL);

-- Tier 3 — Rank III: Elite
INSERT INTO `mob_groups` VALUES (11361, 3549, 288, 'Serket',          0, 128, 99,   50000,  0,      0, NULL);
INSERT INTO `mob_groups` VALUES (11362, 4261, 288, 'Vrtra',           0, 128, 2592, 100000, 100000, 0, NULL);
INSERT INTO `mob_groups` VALUES (11363, 3630, 288, 'Simurgh',         0, 128, 1990, 0,      0,      0, NULL);

-- Tier 4 — Rank IV: Champion
INSERT INTO `mob_groups` VALUES (11364, 2840, 288, 'Nidhogg',         0, 128, 1781, 60000,  0,      0, NULL);
INSERT INTO `mob_groups` VALUES (11365, 2255, 288, 'King_Behemoth',   0, 128, 1450, 75000,  0,      0, NULL);
INSERT INTO `mob_groups` VALUES (11366, 2265, 288, 'Kirin',           0, 128, 2819, 60000,  60000,  0, NULL);

-- Tier 5 — Rank V: Legend
INSERT INTO `mob_groups` VALUES (11367, 21,   288, 'Absolute_Virtue',    0, 128, 3,    66000,  0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11368, 7175, 288, 'Pandemonium_Warden', 0, 128, 1977, 147000, 0, 0, NULL);
INSERT INTO `mob_groups` VALUES (11369, 3604, 288, 'Shinryu',            0, 128, 2238, 0,      0, 0, NULL);
