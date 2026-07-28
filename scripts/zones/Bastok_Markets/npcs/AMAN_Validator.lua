-----------------------------------
-- Area: Bastok Markets
-- NPC: A.M.A.N Validator
-- !pos -338.18 -10 -180.19 235
-- Disabled on Relaunch: the retail Deeds catalog bypasses custom gear progression.
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onSpawn = function(npc)
    npc:setStatus(xi.status.DISAPPEAR)
end

entity.onTrigger = function(player, npc)
end

entity.onTrade = function(player, npc, trade)
end

entity.onEventUpdate = function(player, csid, option, npc)
end

entity.onEventFinish = function(player, csid, option, npc)
end

return entity
