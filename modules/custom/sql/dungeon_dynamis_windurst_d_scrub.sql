-- ============================================================
-- dungeon_dynamis_windurst_d_scrub.sql
-- Wipes the native mob population of Dynamis-Windurst_[D] (zone 296).
--
-- "The Empyreal Paradox" (id: cloister_of_sorrow) uses this zone.
-- The 121 native Divergence mob_groups would interfere with our spawns.
--
-- No GetFirstID exclusions needed — [D] zones have no IDs.lua.
--
-- To apply:
--   mysql -u root -p xidb < modules/custom/sql/dungeon_dynamis_windurst_d_scrub.sql
-- ============================================================

DELETE FROM `mob_spawn_points`
 WHERE `mobid` BETWEEN 17989632 AND 17993727;

DELETE FROM `mob_groups`
 WHERE `zoneid` = 296;
