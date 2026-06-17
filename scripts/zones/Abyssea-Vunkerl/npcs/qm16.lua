-----------------------------------
-- Zone: Abyssea-Vunkerl
--  NPC: qm16 (???)
-- Spawns Karkadann
-- !pos -158 -32 118 217
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_VUNKERL]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.KARKADANN_OFFSET + 0, {})
end

return entity
