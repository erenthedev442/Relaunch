-- ============================================================================
-- spinning_attack_aoe.sql
--
-- Spinning Attack / "Spinning Fists" (weaponskillid 6) ships as aoe=2 /
-- radius=4: a 4-yalm circle around the aimed-at target. Bump radius 4 -> 20.
-- Still target-centered (aoe=2).
--
-- weapon_skills is cached at map boot, so this needs a MAP RESTART.
-- ============================================================================

UPDATE `weapon_skills`
SET `radius` = 20
WHERE `weaponskillid` = 6
  AND `name` = 'spinning_attack';
