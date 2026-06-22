-- Make all three Deeds stackable up to 99 (base item_basic.sql sets stackSize=1).
UPDATE `item_basic` SET `stackSize` = 99 WHERE `itemid` IN (1851, 1854, 1870);
