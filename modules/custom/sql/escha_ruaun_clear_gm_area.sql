-- ============================================================================
-- escha_ruaun_clear_gm_area.sql
-- ----------------------------------------------------------------------------
-- Removes the default/normal roaming mobs that spawn within 100 yalms of the
-- Game Master (wave-master) NPC in Escha - Ru'Aun (zone 289), so the entry
-- plaza where players zone in / start GM wave fights stays clear of trash.
--
-- The GM NPC sits at (x=3.000, y=-34.277, z=-466.980) -- see
-- modules/custom/lua/game_master_catalog.lua (npcPos). Horizontal (x,z)
-- distance was used for the 100-yalm radius.
--
-- SCOPE (verified before writing):
--   * Targets ONLY normal spawns -- mob_groups.spawntype = 0 -- in zone 289.
--     Within 100 yalms that is exactly 18 "Eschan Zdei" spawn points.
--   * NMs / scripted pops (spawntype 128) in range are deliberately LEFT
--     ALONE: Warder of Temperance, Sava Savanovic, and Seiryu (Escha) stay.
--   * Zone scoping uses the zone encoded in the mobid ((mobid>>12)&0xFFF=289)
--     because mob_groups' PK is (groupid, zoneid) -- groupid alone is reused
--     across 50+ zones, so a groupid-only join is NOT zone-safe.
--   * Eschan Zdei spawn points elsewhere in zone 289 (outside 100 yalms) are
--     untouched -- this deletes the 18 in-range instances by explicit mobid.
--   * mob_groups is NOT touched (the Eschan_Zdei group still governs its other
--     spawn points); only the 18 individual spawn-point rows are removed.
--
-- This is data-only: no recompile. The change takes effect when zone 289 next
-- loads its spawn list (a map-server restart, or a zone reload).
--
-- Apply once against the live database:
--   "C:\Program Files\MariaDB 10.6\bin\mysql.exe" -u root -pwarrior3 xidb < modules/custom/sql/escha_ruaun_clear_gm_area.sql
--
-- Idempotent: the DELETE is keyed on the 18 exact mobids, so re-running it once
-- the rows are gone is a harmless no-op. Lives in modules/custom/sql so it
-- re-applies AFTER any core mob_spawn_points reimport (which would restore the
-- stock Eschan Zdei rows), keeping the plaza clear across rebuilds.
-- ============================================================================

DELETE FROM `mob_spawn_points`
 WHERE `mobid` IN (
     17960961, 17960962, 17960964, 17960965, 17960966, 17960967,
     17960968, 17960969, 17960970, 17960971, 17960972, 17960974,
     17960984, 17960985, 17960986, 17960987, 17960988, 17960990
 );


-- ============================================================================
-- REVERSE (manual rollback -- restores the 18 removed Eschan Zdei spawns):
--
-- INSERT INTO `mob_spawn_points`
--     (`mobid`,`spawnslotid`,`mobname`,`polutils_name`,`groupid`,`minLevel`,`maxLevel`,`pos_x`,`pos_y`,`pos_z`,`pos_rot`)
-- VALUES
--     (17960961, 0, 'Eschan_Zdei', 'Eschan Zdei', 1, 81, 89, 14.720, -40.500, -416.540, 64),
--     (17960962, 0, 'Eschan_Zdei', 'Eschan Zdei', 1, 81, 89, 12.364, -40.500, -417.750, 64),
--     (17960964, 0, 'Eschan_Zdei', 'Eschan Zdei', 1, 81, 89, -30.530, -40.700, -375.390, 64),
--     (17960965, 0, 'Eschan_Zdei', 'Eschan Zdei', 1, 81, 89, 30.312, -40.700, -377.250, 64),
--     (17960966, 0, 'Eschan_Zdei', 'Eschan Zdei', 1, 81, 89, 39.249, -40.700, -379.840, 64),
--     (17960967, 0, 'Eschan_Zdei', 'Eschan Zdei', 1, 81, 89, -1.893, -40.500, -382.830, 64),
--     (17960968, 0, 'Eschan_Zdei', 'Eschan Zdei', 1, 81, 89, 35.423, -40.700, -462.140, 64),
--     (17960969, 0, 'Eschan_Zdei', 'Eschan Zdei', 1, 81, 89, 83.440, -40.700, -443.230, 64),
--     (17960970, 0, 'Eschan_Zdei', 'Eschan Zdei', 1, 81, 89, 51.936, -40.700, -441.480, 64),
--     (17960971, 0, 'Eschan_Zdei', 'Eschan Zdei', 1, 81, 89, 52.965, -24.780, -411.380, 64),
--     (17960972, 0, 'Eschan_Zdei', 'Eschan Zdei', 1, 81, 89, 57.673, -24.500, -418.900, 64),
--     (17960974, 0, 'Eschan_Zdei', 'Eschan Zdei', 1, 81, 89, 79.796, -24.500, -418.470, 64),
--     (17960984, 0, 'Eschan_Zdei', 'Eschan Zdei', 1, 81, 89, -29.450, -40.700, -460.670, 64),
--     (17960985, 0, 'Eschan_Zdei', 'Eschan Zdei', 1, 81, 89, -30.130, -40.700, -457.340, 64),
--     (17960986, 0, 'Eschan_Zdei', 'Eschan Zdei', 1, 81, 89, -23.950, -40.700, -458.820, 64),
--     (17960987, 0, 'Eschan_Zdei', 'Eschan Zdei', 1, 81, 89, -56.610, -24.500, -412.290, 64),
--     (17960988, 0, 'Eschan_Zdei', 'Eschan Zdei', 1, 81, 89, -52.070, -32.500, -385.540, 64),
--     (17960990, 0, 'Eschan_Zdei', 'Eschan Zdei', 1, 81, 89, -46.690, -24.500, -432.428, 64);
-- ============================================================================
