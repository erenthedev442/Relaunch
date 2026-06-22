-----------------------------------
-- Zone: Abyssea-Uleguerand
--  NPC: qm16 (???)
-- Spawns Apademak
-- !pos -332 -156 346 253
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_ULEGUERAND]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.APADEMAK_OFFSET + 4, {})
end

return entity
