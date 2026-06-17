-----------------------------------
-- Zone: Abyssea-Vunkerl
--  NPC: qm20 (???)
-- Spawns Karkadann
-- !pos -157 -31 104 217
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_VUNKERL]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.KARKADANN_OFFSET + 4, {})
end

return entity
