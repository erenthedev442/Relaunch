-- ============================================================
-- dungeon_dynamis_sandoria_d_scrub.sql
-- Wipes the native mob population of Dynamis-San_dOria_[D] (zone 294)
-- so the Dungeon System can use it as a clean dungeon arena.
--
-- Why: "The Outer Bastion" (id: whispering_halls) uses this zone.
-- The 121 native Divergence mob_groups would compete with our spawns.
--
-- No GetFirstID exclusions needed: Dynamis [D] zones have no IDs.lua.
-- All 121 mob_groups can be safely deleted.
--
-- Consequences (acknowledge before applying):
--   * Dynamis-San_dOria [D] Divergence content will not function.
--   * On this server, Dynamis Divergence is not active content.
--
-- Reversibility: re-run sql/mob_spawn_points.sql + sql/mob_groups.sql.
-- Idempotent — safe to apply twice.
--
-- To apply:
--   mysql -u root -p xidb < modules/custom/sql/dungeon_dynamis_sandoria_d_scrub.sql
-- ============================================================

DELETE FROM `mob_spawn_points`
 WHERE `mobid` BETWEEN 17981440 AND 17985535;

DELETE FROM `mob_groups`
 WHERE `zoneid` = 294;
