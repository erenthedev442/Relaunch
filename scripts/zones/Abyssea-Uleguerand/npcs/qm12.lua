-----------------------------------
-- Zone: Abyssea-Uleguerand
--  NPC: qm12 (???)
-- Spawns Apademak
-- !pos -332 -155 361 253
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_ULEGUERAND]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.APADEMAK_OFFSET + 0, {})
end

return entity
