-- ============================================================================
-- Reisenjima Geas Fete owns NM spawning through its ???/key-item flow.
--
-- Keep the field population (groups 1-26), but remove the stock Ascended,
-- Geas Fete, boss-add, and Mireu spawn points (groups 27-91). Geas_Fete.lua
-- inserts its selected NM dynamically, so leaving these rows in place creates
-- permanently roaming duplicates beside the on-demand encounter.
--
-- The mobid zone check is mandatory: group IDs are reused between zones.
-- This DELETE is idempotent and takes effect after the next map restart.
-- ============================================================================

DELETE FROM `mob_spawn_points`
WHERE ((`mobid` >> 12) & 0xFFF) = 291
  AND `groupid` BETWEEN 27 AND 91;
