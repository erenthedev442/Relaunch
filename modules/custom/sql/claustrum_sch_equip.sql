-- Allow Scholar to equip every stage of Claustrum (relic staff).
-- SCH is bit 19 in the item_equipment jobs mask (524288).
UPDATE `item_equipment`
SET `jobs` = `jobs` | 524288
WHERE `itemId` IN
(
    18330, 18331, 18648, 18662, 18676,
    19757, 19850, 21135, 21136, 22060
);
