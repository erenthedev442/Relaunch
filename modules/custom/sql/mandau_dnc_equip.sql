-- Allow Dancer to equip every stage of Mandau.
-- DNC is bit 18 in the item_equipment jobs mask (262144).
UPDATE `item_equipment`
SET `jobs` = `jobs` | 262144
WHERE `itemId` IN
(
    18270, 18271, 18638, 18652, 18666,
    19747, 19840, 20555, 20556, 20583
);
