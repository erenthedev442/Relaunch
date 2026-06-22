-----------------------------------
-- Zone: Abyssea-Uleguerand
--  NPC: qm1 (???)
-- Spawns Ironclad Triturator
-- !pos -10 -175 56 253
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_ULEGUERAND]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.IRONCLAD_TRITURATOR, {})
end

return entity
