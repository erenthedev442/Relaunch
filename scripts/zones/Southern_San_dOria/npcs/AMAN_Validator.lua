-----------------------------------
-- Area: Southern San d'Oria
-- NPC: A.M.A.N Validator
-- !pos -83.07 1 -55.58 230
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
