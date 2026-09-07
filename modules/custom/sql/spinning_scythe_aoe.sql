-- ============================================================================
-- spinning_scythe_aoe.sql
--
-- Spinning Scythe (weaponskillid 100) ships as aoe=2 / radius=4: a 4-yalm
-- circle around the aimed-at target. That is the same tight splash as Circle
-- Blade / Spinning Attack, so anything not packed onto the target is missed.
--
-- Bump radius 4 -> 10 to match Cyclone / Shockwave / Earth Crusher.
-- Still target-centered (aoe=2).
--
-- weapon_skills is cached at map boot, so this needs a MAP RESTART.
-- Idempotent UPDATE; custom override so it survives upstream merges.
-- ============================================================================

UPDATE `weapon_skills`
SET `radius` = 10
WHERE `weaponskillid` = 100
  AND `name` = 'spinning_scythe';
