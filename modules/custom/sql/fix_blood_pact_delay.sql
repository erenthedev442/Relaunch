-- Blood Pact delay progression repairs.
--
-- Glyphic Pigaches +4 shipped with BP_DELAY_II -3, which increases Blood Pact
-- recast instead of reducing it. Keep this runtime repair beside the source SQL
-- correction so existing databases and fresh installs receive the same value.
UPDATE `item_mods`
SET `value` = 3
WHERE `itemId` = 24112
  AND `modId` = 541
  AND `value` = -3;
