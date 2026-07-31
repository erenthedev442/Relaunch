-- Allow Geomancer to equip every stage of Mjollnir (relic club).
-- GEO is bit 20 in the item_equipment jobs mask (1048576).
UPDATE `item_equipment`
SET `jobs` = `jobs` | 1048576
WHERE `itemId` IN
(
    18324, 18325, 18647, 18661, 18675,
    19756, 19849, 21060, 21061, 21077
);
