-----------------------------------
-- Zone: Abyssea-Vunkerl
--  NPC: qm18 (???)
-- Spawns Sedna
-- !pos 403 -31 375 217
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_VUNKERL]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.SEDNA_OFFSET + 4, {})
end

return entity
