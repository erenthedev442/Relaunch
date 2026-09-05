-- ============================================================================
-- Yoichi's Quiver (26343) + Moonbeam Cape (26268)
--
-- Quiver shipped as USABLE_TYPE with no CANEQUIP, so the client cannot put
-- it on the waist. Retail is a waist enchantment (RNG/SAM) that you use
-- for 99 Yoichi's Arrows. item_equipment / item_usable / lua already exist.
--
-- Cape is an HP/DT back: HP+250, Damage Taken -5%. HQ is Moonlight
-- (HP+275 / DT-6%). Apply, then restart the map (item data is cached
-- at startup). Idempotent.
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
  (26268,   2,  250),  -- HP +250
  (26268, 160, -500);  -- Damage taken -5%
