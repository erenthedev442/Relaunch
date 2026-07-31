-- Allow Puppetmaster to equip every stage of Spharai (relic H2H).
-- PUP is bit 17 in the item_equipment jobs mask (131072).
UPDATE `item_equipment`
SET `jobs` = `jobs` | 131072
WHERE `itemId` IN
(
    18264, 18265, 18637, 18651, 18665,
    19746, 19839, 20480, 20481, 20509
);
