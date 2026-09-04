-- ============================================================================
-- Yoichi's Quiver (26343) + Moonbeam Cape (26268)
--
-- Quiver shipped as USABLE_TYPE with no CANEQUIP, so the client cannot put
-- it on the waist. Retail is a waist enchantment (RNG/SAM) that you use
-- for 99 Yoichi's Arrows. item_equipment / item_usable / lua already exist.
--
-- Cape had no authoritative item_mods row. The derived snapshot had filler
-- stats and no Damage Taken, so HP/DT from the DAT never applied.
--
-- Apply, then restart the map (item data is cached at startup). Idempotent.
-- ============================================================================

UPDATE `item_basic`
SET
  `type`  = 6,
  `flags` = `flags` | 2048,
  `aH`    = 23
WHERE `itemid` = 26343;

DELETE FROM `item_mods` WHERE `itemId` = 26268;
INSERT INTO `item_mods` (`itemId`, `modId`, `value`) VALUES
  (26268,   1,   14),  -- DEF +14
  (26268,   2,   50),  -- HP +50
  (26268,   5,   50),  -- MP +50
  (26268,  23,   15),  -- Attack +15
  (26268,  24,   15),  -- Ranged Attack +15
  (26268,  25,   15),  -- Accuracy +15
  (26268,  26,   15),  -- Ranged Accuracy +15
  (26268,  28,   15),  -- Magic Atk. Bonus +15
  (26268,  29,    5),  -- Magic Def. Bonus +5
  (26268,  30,   15),  -- Magic Accuracy +15
  (26268, 160, -500);  -- Damage taken -5%
