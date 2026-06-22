-- Make Deed of Moderation (1854) stackable up to 99.
-- The base item_basic.sql sets stackSize=1 for all three Deeds.
UPDATE `item_basic` SET `stackSize` = 99 WHERE `itemid` = 1854;
