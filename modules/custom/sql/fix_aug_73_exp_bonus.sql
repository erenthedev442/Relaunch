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
-- On deploy this is applied automatically by tools/_apply_changed_custom_sql.sh
-- whenever this file's checksum changes (the header is refreshed below to force
-- exactly that). sql/augments.sql is never re-imported on deploy, so once this
-- runs the modId sticks across restarts -- it only reverts on a full DB re-import.
--
-- After applying:
--   1. Restart the map server so the augments table is reloaded.
--   2. Re-zone any character who already has the augmented piece equipped
--      (the mod attaches on item-load, which fires on zone or relog).
--
-- 2026-06-12: re-asserted alongside restoring the Exp./Cap. Point catalysts to
-- modules/custom/lua/augment_catalog.lua (a catalog regeneration had dropped the
-- hand-maintained "Progression (Exp / Cap)" section; the generator now emits it).
-- This Exp. Point catalyst is cosmetic until this row is live, so we want it to
-- re-apply on the next deploy.
-- ----------------------------------------------------------------------------

-- Unconditional (not `AND modId = 0`): augId 73 is "Exp. Point" on this server
-- and must always map to Mod::EXP_BONUS. Re-running is a harmless no-op when the
-- value already matches, so this is safe for the every-changed-deploy ledger.
UPDATE `augments`
SET    `modId` = 382      -- Mod::EXP_BONUS (see src/map/modifier.h:692)
WHERE  `augmentId` = 73;
