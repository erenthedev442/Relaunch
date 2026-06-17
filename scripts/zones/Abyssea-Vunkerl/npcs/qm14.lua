-----------------------------------
-- Zone: Abyssea-Vunkerl
--  NPC: qm14 (???)
-- Spawns Sedna
-- !pos 403 -31 390 217
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_VUNKERL]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.SEDNA_OFFSET + 0, {})
end

return entity
