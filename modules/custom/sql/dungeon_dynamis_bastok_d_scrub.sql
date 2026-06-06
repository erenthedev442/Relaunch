-- ============================================================
-- dungeon_dynamis_bastok_d_scrub.sql
-- Wipes the native mob population of Dynamis-Bastok_[D] (zone 295).
--
-- "The Voidwalker Arena" (id: voidwalker_arena) uses this zone.
-- The 121 native Divergence mob_groups would interfere with our spawns.
--
-- No GetFirstID exclusions needed — [D] zones have no IDs.lua.
--
-- To apply:
--   mysql -u root -p xidb < modules/custom/sql/dungeon_dynamis_bastok_d_scrub.sql
-- ============================================================

DELETE FROM `mob_spawn_points`
 WHERE `mobid` BETWEEN 17985536 AND 17989631;

DELETE FROM `mob_groups`
 WHERE `zoneid` = 295;
