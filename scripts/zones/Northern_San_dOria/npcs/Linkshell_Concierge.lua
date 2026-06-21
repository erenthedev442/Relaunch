-----------------------------------
-- Area: Northern San d'Oria
--  NPC: Linkshell Concierge
-- Hands out a New Linkshell so players can establish their own linkshell.
-- Shared logic in scripts/globals/linkshell_concierge.lua.
-----------------------------------
local lsConcierge = require('scripts/globals/linkshell_concierge')

local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    lsConcierge.onTrigger(player, npc)
end

entity.onEventUpdate = function(player, csid, option, npc)
end

entity.onEventFinish = function(player, csid, option, npc)
end

return entity
