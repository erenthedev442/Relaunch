-- Hauksbok Bullet (22295) shipped with subskill 0 (bolt).
-- Guns are subskill 1; the server unequips mismatched ammo on SLOT_AMMO.
-- Same delay/dmg as Chrono Bullet. Apply, then restart the map.

UPDATE `item_weapon`
SET `subskill` = 1
WHERE `itemId` = 22295
  AND `subskill` = 0;
