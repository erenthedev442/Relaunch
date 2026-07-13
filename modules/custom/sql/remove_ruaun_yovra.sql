-- ============================================================================
-- remove_ruaun_yovra.sql
--
-- Stop "Eschan Yovra" from spawning in Escha - Ru'Aun (zone 289) -- it clutters
-- the wavemaster / GameMaster hub airspace (owner request 2026-07-12, screenshot).
--
-- Deletes only that mob's spawn points, scoped by BOTH the exact mobname AND the
-- zone bits of mobid ((mobid >> 12) & 0xFFF = 289), so it can never touch a Yovra
-- in any OTHER zone or any other mob here. 5 rows. No spawn point = the zone stops
-- spawning it (mob_groups/mob_pools rows are left alone, harmless). Idempotent
-- (a DELETE re-runs to nothing); applies after the base import so it re-removes
-- them each deploy if the base mob_spawn_points is re-imported.
--
-- SAFETY: mob_spawn_points scrubs MUST be zone-scoped (never by groupid) -- an
-- unscoped delete once gutted the table. This is name+zone scoped, the tightest.
-- Mirrors modules/custom/sql/remove_ruaun_amoeban.sql. Takes effect on the next
-- map restart (already-spawned instances despawn on reload and won't respawn).
-- ============================================================================

DELETE FROM `mob_spawn_points`
WHERE `mobname` = 'Eschan_Yovra'
  AND ((`mobid` >> 12) & 0xFFF) = 289;   -- Escha - Ru'Aun only
