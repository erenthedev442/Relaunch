-----------------------------------
-- Zone: Abyssea-Misareaux
--  NPC: qm20 (???)
-- Spawns Ironclad Pulverizer
-- !pos -214 -31 160 216
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_MISAREAUX]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.IRONCLAD_PULVERIZER_OFFSET + 5, {})
end

return entity
