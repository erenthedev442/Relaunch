-----------------------------------
-- Zone: Abyssea-Misareaux
--  NPC: qm17 (???)
-- Spawns Cirein-croin
-- !pos 54 -15 520 216
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_MISAREAUX]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.CIREIN_CROIN_OFFSET + 5, {})
end

return entity
