-- ----------------------------------------------------------------------------
-- fix_aug_73_exp_bonus.sql
--
-- Upstream LSB ships sql/augments.sql with this row:
--     INSERT INTO `augments` VALUES (73,0,0,33,0,0); -- Exp. Point +33%
-- The third column is modId. With modId=0, the augment writes NO mod to the
-- player when the gear is equipped — the engine has nothing to read.
-- Compare to the sibling row for Cap. Point +33% which uses modId=915
-- (Mod::CAPACITY_BONUS) and works correctly.
--
-- The engine reads Mod::EXP_BONUS (mod 382) on the character in
-- charutils.cpp::AddExperiencePoints and multiplies incoming EXP by
-- `getMod(Mod::EXP_BONUS) / 100`. So all we need is to point augId 73 at
-- that mod.
--
-- Apply once with: dbtool, or:
--    mysql -u <user> -p <db> < modules/custom/sql/fix_aug_73_exp_bonus.sql
--
-- After applying:
--   1. Restart the map server so the augments table is reloaded.
--   2. Re-zone any character who already has the augmented piece equipped
--      (the mod attaches on item-load, which fires on zone or relog).
-- ----------------------------------------------------------------------------

UPDATE `augments`
SET    `modId` = 382      -- Mod::EXP_BONUS (see src/map/modifier.h:692)
WHERE  `augmentId` = 73
   AND `modId`     = 0;
