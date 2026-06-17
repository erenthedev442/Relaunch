-----------------------------------
-- Zone: Abyssea-Misareaux
--  NPC: qm24 (???)
-- Spawns Ironclad Pulverizer
-- !pos -199 -31 145 216
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_MISAREAUX]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.IRONCLAD_PULVERIZER_OFFSET + 10, {})
end

return entity
