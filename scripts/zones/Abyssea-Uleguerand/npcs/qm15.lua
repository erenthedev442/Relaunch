-----------------------------------
-- Zone: Abyssea-Uleguerand
--  NPC: qm15 (???)
-- Spawns Pantokrator
-- !pos -198 -175 140 253
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_ULEGUERAND]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.PANTOKRATOR_OFFSET + 4, {})
end

return entity
