-----------------------------------
-- Zone: Abyssea-Misareaux
--  NPC: qm13 (???)
-- Spawns Cirein-croin
-- !pos 39.146 -15.500 519.988 216
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_MISAREAUX]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.CIREIN_CROIN_OFFSET + 0, {})
end

return entity
