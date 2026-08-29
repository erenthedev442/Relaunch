-- Retired: starter Gear Moogle bypassed intended equipment progression.
-- Keep that custom NPC deleted. Restore the four retail Artisan Moogles
-- (Southern San d'Oria, Bastok Markets, Windurst Woods, Ru'Lude Gardens)
-- so players can buy/expand a Mog Sack. The login auto-grant in
-- open_mog_containers.lua is disabled (crash), so these NPCs are the path.
DELETE FROM `npc_list` WHERE `npcid` = 17720035;

UPDATE `npc_list`
SET `status` = 0
WHERE `npcid` IN (17719633, 17739947, 17764601, 17772833);