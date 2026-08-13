-- Retired: starter gear and home-nation Artisan Moogles bypass intended
-- equipment/crafting progression. Delete the custom Gear Moogle and hide all
-- four retail Artisan Moogles, including Ru'Lude Gardens.
DELETE FROM `npc_list` WHERE `npcid` = 17720035;

UPDATE `npc_list`
SET `status` = 2
WHERE `npcid` IN (17719633, 17739947, 17764601, 17772833);