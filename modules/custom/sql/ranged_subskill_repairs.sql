-- Gun/bullet classification repairs.
-- Marksmanship subskill 1 is the gun/bullet family; 0 is crossbow/bolt.
-- Keep this deployment overlay even though base item_weapon.sql is corrected,
-- so older live databases are repaired without requiring a full table import.

UPDATE `item_weapon`
SET `subskill` = 1
WHERE `itemId` IN
(
    22159, -- Prime Gun
    22160, -- Earp stages
    22161,
    22162,
    22164,
    22308  -- Bayeux Bullet
);
