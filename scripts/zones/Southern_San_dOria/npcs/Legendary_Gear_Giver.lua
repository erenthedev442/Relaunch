-----------------------------------
-- Area: Southern San d'Oria
-- NPC: Legendary Gear Giver
-- Retired starter-kit NPC. Not spawned in npc_list.
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrigger = function(player, npc)
    player:printToPlayer('Starter gear is not handed out here.', xi.msg.channel.SYSTEM_3)
end

return entity
