-- ============================================================
-- dungeon_dynamis_windurst_scrub.sql
-- Wipes the native mob population of Dynamis-Windurst (zone 187)
-- so the Dungeon System can use it as a clean dungeon arena.
--
-- Why: "The Empyreal Paradox" (id: cloister_of_sorrow) uses this
-- zone. The 59 native Dynamis mob_groups (Yagudo Priests, Tzee Xicu
-- Idol mobs, avatar icons, etc.) would interfere with our spawns.
--
-- What gets deleted:
--   * ALL mob_spawn_points rows in the zone 187 mobid range
--     (17543168 .. 17547263).
--   * ALL mob_groups rows with zoneid = 187.
--
-- No GetFirstID exclusions needed: Dynamis-Windurst/IDs.lua
-- references all mobs by direct mobid, not by name.
--
-- Consequences (acknowledge before applying):
--   * Dynamis-Windurst will have zero native mobs. The Dynamis quest
--     system for this zone will not function.
--   * On this server, Dynamis content is not active.
--
-- Reversibility:
--   * Re-run sql/mob_spawn_points.sql and sql/mob_groups.sql.
--   * Idempotent — safe to apply twice.
--
-- To apply:
--   mysql -u root -p xidb < modules/custom/sql/dungeon_dynamis_windurst_scrub.sql
-- ============================================================

DELETE FROM `mob_spawn_points`
 WHERE `mobid` BETWEEN 17543168 AND 17547263;

DELETE FROM `mob_groups`
 WHERE `zoneid` = 187;
