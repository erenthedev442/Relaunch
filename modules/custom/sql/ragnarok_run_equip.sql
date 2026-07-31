-- Allow Rune Fencer to equip every stage of Ragnarok (relic great sword).
-- RUN is bit 21 in the item_equipment jobs mask (2097152).
UPDATE `item_equipment`
SET `jobs` = `jobs` | 2097152
WHERE `itemId` IN
(
    18282, 18283, 18640, 18654, 18668,
    19749, 19842, 20745, 20746, 21683
);
