-----------------------------------
-- Zone: Abyssea-Vunkerl
--  NPC: qm22 (???)
-- Spawns Sedna
-- !pos 402 -31 406 217
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_VUNKERL]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.SEDNA_OFFSET + 8, {})
end

return entity
