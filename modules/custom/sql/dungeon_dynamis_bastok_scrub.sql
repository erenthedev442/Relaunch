-- ============================================================
-- dungeon_dynamis_bastok_scrub.sql
-- Wipes the native mob population of Dynamis-Bastok (zone 186)
-- so the Dungeon System can use it as a clean dungeon arena.
--
-- Why: "The Voidwalker Arena" (id: voidwalker_arena) uses this zone.
-- The 46 native Dynamis mob_groups (Quadav Arcanists, Adamantking
-- mobs, refill statues, etc.) would interfere with our spawns.
--
-- What gets deleted:
--   * ALL mob_spawn_points rows in the zone 186 mobid range
--     (17539072 .. 17543167).
--   * ALL mob_groups rows with zoneid = 186.
--
-- No GetFirstID exclusions needed: Dynamis-Bastok/IDs.lua
-- references all mobs by direct mobid, not by name.
--
-- Consequences (acknowledge before applying):
--   * Dynamis-Bastok will have zero native mobs. The Dynamis quest
--     system for this zone will not function.
--   * On this server, Dynamis content is not active.
--
-- Reversibility:
--   * Re-run sql/mob_spawn_points.sql and sql/mob_groups.sql.
--   * Idempotent — safe to apply twice.
--
-- To apply:
--   mysql -u root -p xidb < modules/custom/sql/dungeon_dynamis_bastok_scrub.sql
-- ============================================================

DELETE FROM `mob_spawn_points`
 WHERE `mobid` BETWEEN 17539072 AND 17543167;

DELETE FROM `mob_groups`
 WHERE `zoneid` = 186;
