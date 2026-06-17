-----------------------------------
-- Zone: Abyssea-Vunkerl
--  NPC: qm17 (???)
-- Spawns Bukhis
-- !pos -201 -39 -265 217
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_VUNKERL]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.BUKHIS_OFFSET + 4, {})
end

return entity
