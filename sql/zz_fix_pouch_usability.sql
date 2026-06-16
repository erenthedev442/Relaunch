-- Fix ammo pouches/quivers that were tagged @EQUIPMENT_TYPE/@FLAG_CANEQUIP
-- instead of @USABLE_TYPE/@FLAG_CANUSE, causing "Unable to use item".
-- USABLE_TYPE = 5, EQUIPMENT_TYPE = 6, FLAG_CANUSE = 512, FLAG_CANEQUIP = 2048
UPDATE item_basic
SET    type  = 5,
       flags = (flags & ~2048) | 512
WHERE  itemid IN (15956, 15957, 15958,
                  26343, 26344, 26345, 26346, 26347, 26348, 26349, 26350);
