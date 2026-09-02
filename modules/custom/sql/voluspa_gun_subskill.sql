-- Voluspa Gun (22144) shipped as subskill 0 (crossbow / bolts).
-- Guns are subskill 1 (bullets). Without this the weapon accepts bolts
-- and cannot use bullets.
UPDATE `item_weapon`
   SET `subskill` = 1
 WHERE `itemId` = 22144
   AND `skill` = 26;
