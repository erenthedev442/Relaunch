-- ============================================================
-- hunting_league_escha_migration.sql
-- One-time migration: moves the Hunting League from
-- Reisenjima Henge (zone 292) to Escha - Zi'Tah (zone 288)
-- and clears all native Escha Zi'Tah mob spawns so the zone
-- is left entirely for the Hunting League.
--
-- Zone 210 (GM Home) rows are NOT touched.
-- Re-runnable (DELETE is idempotent once rows are gone).
--
-- Apply:  sudo mysql xidb < modules/custom/sql/hunting_league_escha_migration.sql
-- Then RESTART the map server.
-- ============================================================

-- ---- 1. Clear all native mob spawns from Escha Zi'Tah (zone 288) ----------
--   Scope by the zone encoded in the mobid: (mobid >> 12) & 0xFFF = zoneid.
--   DO NOT join mob_spawn_points to mob_groups on groupid alone -- `groupid`
--   is REUSED across zones, so `ON msp.groupid = mg.groupid WHERE mg.zoneid = 288`
--   matched zone 288's groupids in EVERY zone and deleted mob_spawn_points
--   server-wide. That gutted the table 82,974 -> 11,879 rows on 2026-06-15 and
--   emptied every zone (zone-ID lookups read mob_spawn_points). HL NMs are
--   pure-dynamic (no spawn points), so this never touches them.
DELETE FROM `mob_spawn_points` WHERE ((`mobid` >> 12) & 0xFFF) = 288;

-- ---- 2. Remove old Reisenjima Henge HL mob_groups (zone 292) ---------------
DELETE FROM mob_groups WHERE groupid BETWEEN 11355 AND 11369 AND zoneid = 292;

-- ---- 3. Add Hunting League mob_groups for Escha Zi'Tah (zone 288) ----------
--   Same poolids / dropids / HP / MP as the original 292 rows.
--   Clear existing 288 rows FIRST so these INSERTs are idempotent. Step 2 only
--   removes the old zone-292 rows, so without this a re-run (when this file's
--   checksum changes and the custom-SQL applier re-runs it) hit "Duplicate
--   entry '288-11355'" and aborted the migration mid-file. Zone 210 (GM Home)
--   rows are owned by hunting_league_gm_home_mobs.sql and are NOT touched here.
DELETE FROM mob_groups WHERE groupid BETWEEN 11355 AND 11369 AND zoneid = 288;

-- Tier 1 — Rank I: Initiate
INSERT INTO mob_groups VALUES (11355, 2384, 288, 'Leaping_Lizzy',   0, 128, 103,  0,      0,      0, NULL);
INSERT INTO mob_groups VALUES (11356, 4124, 288, 'Valkurm_Emperor', 0, 128, 571,  0,      0,      0, NULL);
INSERT INTO mob_groups VALUES (11357, 3947, 288, 'Tom_Tit_Tat',     0, 128, 2426, 0,      0,      0, NULL);

-- Tier 2 — Rank II: Hunter
INSERT INTO mob_groups VALUES (11358, 3376, 288, 'Roc',             0, 128, 1990, 0,      0,      0, NULL);
INSERT INTO mob_groups VALUES (11359, 498,  288, 'Bomb_Queen',      0, 128, 334,  47000,  0,      0, NULL);
INSERT INTO mob_groups VALUES (11360, 206,  288, 'Aquarius',        0, 128, 100,  0,      0,      0, NULL);

-- Tier 3 — Rank III: Elite
INSERT INTO mob_groups VALUES (11361, 3549, 288, 'Serket',          0, 128, 99,   50000,  0,      0, NULL);
INSERT INTO mob_groups VALUES (11362, 4261, 288, 'Vrtra',           0, 128, 2592, 100000, 100000, 0, NULL);
INSERT INTO mob_groups VALUES (11363, 3630, 288, 'Simurgh',         0, 128, 1990, 0,      0,      0, NULL);

-- Tier 4 — Rank IV: Champion
INSERT INTO mob_groups VALUES (11364, 2840, 288, 'Nidhogg',         0, 128, 1781, 60000,  0,      0, NULL);
INSERT INTO mob_groups VALUES (11365, 2255, 288, 'King_Behemoth',   0, 128, 1450, 75000,  0,      0, NULL);
INSERT INTO mob_groups VALUES (11366, 2265, 288, 'Kirin',           0, 128, 2819, 60000,  60000,  0, NULL);

-- Tier 5 — Rank V: Legend
INSERT INTO mob_groups VALUES (11367, 21,   288, 'Absolute_Virtue',    0, 128, 3,    66000,  0, 0, NULL);
INSERT INTO mob_groups VALUES (11368, 7175, 288, 'Pandemonium_Warden', 0, 128, 1977, 147000, 0, 0, NULL);
INSERT INTO mob_groups VALUES (11369, 3604, 288, 'Shinryu',            0, 128, 2238, 0,      0, 0, NULL);
