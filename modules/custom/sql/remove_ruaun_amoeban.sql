-- ============================================================================
-- remove_ruaun_amoeban.sql
--
-- Stop "Eschan Amoeban" from spawning in Escha - Ru'Aun (zone 289) -- it clutters
-- the wavemaster / GameMaster hub (owner request 2026-07-10, screenshot).
--
-- Deletes only that mob's spawn points, scoped by BOTH the exact mobname AND the
-- zone bits of mobid ((mobid >> 12) & 0xFFF = 289), so it can never touch Eschan
-- Amoeban in any OTHER Escha zone or any other mob here. ~8 rows. No spawn point =
-- the zone stops spawning it (mob_groups/mob_pools rows are left alone, harmless).
-- Idempotent (a DELETE re-runs to nothing); applies after the base import so it
-- re-removes them each deploy if the base mob_spawn_points is re-imported.
--
-- SAFETY: mob_spawn_points scrubs MUST be zone-scoped (never by groupid) -- an
-- unscoped delete once gutted the table. This is name+zone scoped, the tightest.
-- Takes effect on the next map restart (already-spawned instances despawn on
-- reload and won't respawn).
-- ============================================================================

DELETE FROM `mob_spawn_points`
WHERE `mobname` = 'Eschan_Amoeban'
  AND ((`mobid` >> 12) & 0xFFF) = 289;   -- Escha - Ru'Aun only
