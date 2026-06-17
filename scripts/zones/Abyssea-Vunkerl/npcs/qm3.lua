-----------------------------------
-- Zone: Abyssea-Vunkerl
--  NPC: qm3 (???)
-- Spawns Iku-Turso
-- !pos 244 -32 240 217
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_VUNKERL]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.IKU_TURSO, {})
end

return entity
