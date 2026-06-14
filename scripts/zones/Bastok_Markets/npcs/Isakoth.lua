-----------------------------------
-- Area: Bastok Markets
--  NPC: Isakoth
-- Records of Eminence NPC -- DISABLED on Legendary (FJB).
-- RoE enrollment/objectives AND the Sparks/Accolades shop are turned off in the
-- three starting capitals (San d'Oria, Bastok, Windurst). Adoulin's Eternal Flame
-- is intentionally left active. The NPC stays visible but inert.
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    player:printToPlayer('Records of Eminence and the Sparks exchange are closed on Legendary.', xi.msg.channel.SYSTEM_3)
end

return entity
