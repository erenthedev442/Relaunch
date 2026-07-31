-- Allow Blue Mage to equip every stage of Excalibur (relic sword).
-- BLU is bit 15 in the item_equipment jobs mask (32768).
UPDATE `item_equipment`
SET `jobs` = `jobs` | 32768
WHERE `itemId` IN
(
    18276, 18277, 18639, 18653, 18667,
    19748, 19841, 20645, 20646, 20685
);
