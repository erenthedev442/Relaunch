-- ============================================================
-- dungeon_dynamis_sandoria_scrub.sql
-- Wipes the native mob population of Dynamis-San_dOria (zone 185)
-- so the Dungeon System can use it as a clean dungeon arena.
--
-- Why: "The Outer Bastion" (id: whispering_halls) uses this zone.
-- We dynamically spawn our own mobs via insertDynamicEntity with
-- HL groupIds (11355..11369) registered in zone 210/GM_Home.
-- The 48 native Dynamis mob_groups (Orcish Warmachine, Orc
-- Warmachines, Overlord mobs, etc.) would compete for AI ticks
-- and make the "empty fortress" atmosphere impossible.
--
-- What gets deleted:
--   * ALL mob_spawn_points rows in the zone 185 mobid range
--     (17534976 .. 17539071).
--   * ALL mob_groups rows with zoneid = 185.
--
-- No GetFirstID exclusions needed: Dynamis-San_dOria/IDs.lua
-- references all mobs by direct mobid, not by name, so no
-- GetFirstID calls would fail after this scrub.
--
-- Consequences (acknowledge before applying):
--   * Dynamis-San_dOria will have zero native mobs. The Dynamis
--     quest system for this zone (Overlord Tombstone, time-extension
--     mobs, refill statues) will not function.
--   * On this server, Dynamis content is not active; dungeons are
--     the progression path. This trade-off is accepted.
--
-- Reversibility:
--   * Re-run sql/mob_spawn_points.sql and sql/mob_groups.sql to
--     restore the native population.
--   * This file is idempotent — running it twice is harmless.
--
-- To apply (run once, after the zone swap commit):
--   mysql -u root -p xidb < modules/custom/sql/dungeon_dynamis_sandoria_scrub.sql
-- ============================================================

DELETE FROM `mob_spawn_points`
 WHERE `mobid` BETWEEN 17534976 AND 17539071;

DELETE FROM `mob_groups`
 WHERE `zoneid` = 185;
