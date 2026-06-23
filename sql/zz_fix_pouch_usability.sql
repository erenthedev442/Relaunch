-- Fix ammo pouches/quivers that were tagged @EQUIPMENT_TYPE/@FLAG_CANEQUIP
-- instead of @USABLE_TYPE/@FLAG_CANUSE, causing "Unable to use item".
-- USABLE_TYPE = 5, EQUIPMENT_TYPE = 6, FLAG_CANUSE = 512, FLAG_CANEQUIP = 2048
--
-- (1) PURE usable quivers/pouches -- use to dispense a stack, not equippable.
UPDATE item_basic
SET    type  = 5,
       flags = (flags & ~2048) | 512
WHERE  itemid IN (15956, 15957, 15958,
                  26343, 26344, 26345, 26346);

-- (2) The 4 CUSTOM "Bullet Pouch" items (26347-26350) are DUAL-PURPOSE, exactly
-- like a Warp Ring (equippable gear that is ALSO usable while worn):
--   * EQUIP in the WAIST slot -> RECYCLE 100 = infinite ammo (item_equipment +
--     item_mods come from modules/custom/sql/bullet_pouches_waist.sql), AND
--   * USE to dispense 99 of the matching bullet (item_usable rows +
--     scripts/items/*_bullet_pouch.lua onItemCheck/onItemUse).
-- Verified against Warp Ring (28540): EQUIPMENT type + CANEQUIP, CANUSE *off*
-- (flags 64584). The use fires from item_usable + the script, NOT the CANUSE flag.
-- Lumping these into the usable-only list above stripped CANEQUIP, so they could
-- not be equipped. Keep them OUT of (1).
UPDATE item_basic
SET    type  = 6,
       flags = (flags | 2048) & ~512
WHERE  itemid IN (26347, 26348, 26349, 26350);
