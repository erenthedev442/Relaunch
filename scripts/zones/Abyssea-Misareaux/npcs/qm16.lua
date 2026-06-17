-----------------------------------
-- Zone: Abyssea-Misareaux
--  NPC: qm16 (???)
-- Spawns Ironclad Pulverizer
-- !pos -198 -31 160 216
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_MISAREAUX]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.IRONCLAD_PULVERIZER_OFFSET + 0, {})
end

return entity
