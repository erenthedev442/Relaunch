-----------------------------------
-- Zone: Abyssea-Misareaux
--  NPC: qm21 (???)
-- Spawns Cirein-croin
-- !pos 38 -15 534 216
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_MISAREAUX]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.CIREIN_CROIN_OFFSET + 10, {})
end

return entity
