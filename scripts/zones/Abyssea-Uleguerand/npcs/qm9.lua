-----------------------------------
-- Zone: Abyssea-Uleguerand
--  NPC: qm9 (???)
-- Spawns Chillwing Hwitti
-- !pos -484 -20 -85 253
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_ULEGUERAND]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.CHILLWING_HWITTI, {})
end

return entity
