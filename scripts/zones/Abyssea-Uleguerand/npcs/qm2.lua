-----------------------------------
-- Zone: Abyssea-Uleguerand
--  NPC: qm2 (???)
-- Spawns Dhorme Khimaira
-- !pos -281.411 -155.568 267.682 253
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_ULEGUERAND]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.DHORME_KHIMAIRA, {})
end

return entity
