-- ============================================================
-- dungeon_dynamis_jeuno_d_scrub.sql
-- Wipes the native mob population of Dynamis-Jeuno_[D] (zone 297).
--
-- "The Eternal Throne" (id: eternal_throne) uses this zone.
-- The 121 native Divergence mob_groups would interfere with our spawns.
--
-- No GetFirstID exclusions needed — [D] zones have no IDs.lua.
--
-- To apply:
--   mysql -u root -p xidb < modules/custom/sql/dungeon_dynamis_jeuno_d_scrub.sql
-- ============================================================

DELETE FROM `mob_spawn_points`
 WHERE `mobid` BETWEEN 17993728 AND 17997823;

DELETE FROM `mob_groups`
 WHERE `zoneid` = 297;
