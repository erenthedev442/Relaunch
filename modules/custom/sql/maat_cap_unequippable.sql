-- Maat's Cap (item 15194) is used as the Augment Moogle crit token (consumed on crit).
-- It should not be wearable as actual gear -- set jobs=0 so no job can equip it.
-- Requires xi_map restart (item_equipment is boot-cached).
UPDATE item_equipment SET jobs = 0 WHERE itemId = 15194;
