-----------------------------------
-- Zone: Abyssea-Vunkerl
--  NPC: qm13 (???)
-- Spawns Bukhis
-- !pos -202 -40 -280 217
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_VUNKERL]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.BUKHIS_OFFSET + 0, {})
end

return entity
