-- ============================================================================
-- fell_cleave_aoe.sql
--
-- Player weapon_skills.aoe:
--   0/1 = single target
--   2   = circular AoE around the aimed-at target
--   3   = circular AoE around the attacker (360 degrees)
--
-- Fell Cleave was aoe=2, so it only splashed a 4-yalm circle on the targeted
-- mob. That reads as a frontal/directional cleave: enemies beside or behind
-- the player are missed unless they are packed onto the target.
--
-- aoe=3 keeps the same radius but centers it on the player.
-- weapon_skills is cached at map boot, so this needs a map restart.
-- The C++ isAoE()/radius-type change must ship with this UPDATE.
-- Player/trust WS findWithinArea must pass TARGET_ENEMY or aoe=3 is
-- treated as an ally-only self-centered buff and deals 0 damage.
-- ============================================================================

UPDATE `weapon_skills`
SET `aoe` = 3
WHERE `weaponskillid` = 91
  AND `name` = 'fell_cleave';
