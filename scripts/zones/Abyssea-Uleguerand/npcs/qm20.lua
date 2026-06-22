-----------------------------------
-- Zone: Abyssea-Uleguerand
--  NPC: qm20 (???)
-- Spawns Apademak
-- !pos -332 -156 377 253
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_ULEGUERAND]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.APADEMAK_OFFSET + 8, {})
end

return entity
