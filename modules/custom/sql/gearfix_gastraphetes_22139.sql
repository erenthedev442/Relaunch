-- Item 22139 (Gastraphetes iLvl 119 variant) had incomplete mods:
-- aftermath=33 (Tier 1 instead of Tier 3=43), missing WSD+30%, BARRAGE_ACC=0.
-- Bring it in line with the other max iLvl Gastraphetes versions (21246/21247/21266).
UPDATE `item_mods` SET `value` = 43 WHERE `itemId` = 22139 AND `modId` = 256;
INSERT IGNORE INTO `item_mods` (`itemId`, `modId`, `value`) VALUES (22139, 787, 30);
UPDATE `item_mods` SET `value` = 70 WHERE `itemId` = 22139 AND `modId` = 420;
