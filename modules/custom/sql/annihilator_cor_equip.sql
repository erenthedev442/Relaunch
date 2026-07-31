-- Allow Corsair to equip every stage of Annihilator (relic gun).
-- COR is bit 16 in the item_equipment jobs mask (65536).
UPDATE `item_equipment`
SET `jobs` = `jobs` | 65536
WHERE `itemId` IN
(
    18336, 18337, 18649, 18663, 18677,
    19758, 19851, 21260, 21261, 21267, 22140
);
