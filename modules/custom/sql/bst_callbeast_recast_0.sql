-- Remove recast timers from Call Beast (id 85) and Bestial Loyalty (id 387).
-- Retail: Call Beast 5:00, Bestial Loyalty 20:00. Setting recast=0 makes both
-- instantly reusable (QoL for jug-pet BST gameplay on Legendary).
UPDATE `abilities` SET `recastTime` = 0 WHERE `abilityId` IN (85, 387);
