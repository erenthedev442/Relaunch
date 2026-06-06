-- ----------------------------------------------------------------------------
-- fix_aug_137_regen.sql
--
-- Buffs the Regen augment from the stock +1 to +5 (per single application).
--
-- Stock LSB ships sql/augments.sql with:
--     INSERT INTO `augments` VALUES (137,0,370,1,0,0); -- Regen+1
-- (augmentId 137 -> modId 370 = Mod::REGEN, value 1.) This raises that base
-- value to 5, so a single Regen augment grants Regen+5.
--
-- THREE PLACES are kept in sync so the change survives every reload path:
--   1. THIS custom override -> re-asserts value=5 in the DB after any reimport
--      (custom/sql loads AFTER core sql, so it always wins).
--   2. sql/augments.sql line ~188 -> edited to 5 as well, so a plain core
--      reimport AND the augment_catalog.lua regeneration (refresh-site.bat reads
--      that file) both produce 5. If an upstream LSB merge ever reverts that
--      line to 1, this override still keeps the live DB at 5 -- just re-fix the
--      core line when you notice it.
--   3. modules/custom/lua/augment_catalog.lua [859] base/label -> set to 5 /
--      'Regen+5', because the Augment Moogle reads catalog `base` for its
--      stacking math (Augment_Moogle.lua:366) and the trade-message label.
--
-- Stacking note: the Augment Sage boost caps a maxed 4-catalyst trade at
--   base * 4 * 2.0 (mastery) * 1.5 (affinity) * 2.0 (crit) = base * 24
-- so a fully-boosted Regen augment now tops out at 5 * 24 = Regen+120
-- (was 1 * 24 = +24).
--
-- Apply once with: dbtool, or:
--    "C:\Program Files\MariaDB 10.6\bin\mysql.exe" -u root -pwarrior3 xidb < modules/custom/sql/fix_aug_137_regen.sql
--
-- After applying:
--   1. Restart the map server so the augments table is reloaded.
--   2. Re-zone any character already wearing a Regen-augmented piece (the mod
--      attaches on item-load, which fires on zone or relog).
--
-- Idempotent: re-running just sets value=5 again (no-op once applied).
--
-- REVERSE (restore stock Regen+1):
--   UPDATE `augments` SET `value` = 1 WHERE `augmentId` = 137 AND `modId` = 370;
--   ...and revert sql/augments.sql + augment_catalog.lua [859] to 1 / 'Regen+1'.
-- ----------------------------------------------------------------------------

UPDATE `augments`
SET    `value` = 5
WHERE  `augmentId` = 137
   AND `modId`     = 370;   -- Mod::REGEN
