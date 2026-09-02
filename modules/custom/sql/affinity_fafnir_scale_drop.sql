-- Retail Fafnir dropid 805 has Dragon Scales (867) but not Fafnir's Scale
-- (10037), the affinity trophy. Nidhogg 1781 already lists Nidhogg's Scales.
DELETE FROM `mob_droplist` WHERE `dropId` = 805 AND `itemId` = 10037;
INSERT INTO `mob_droplist` VALUES (805, 0, 0, 1000, 10037, 150);
