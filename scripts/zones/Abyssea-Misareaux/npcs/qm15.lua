-----------------------------------
-- Zone: Abyssea-Misareaux
--  NPC: qm15 (???)
-- Spawns Sobek
-- !pos 428 23 -376 216
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_MISAREAUX]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.SOBEK_OFFSET + 0, {})
end

return entity
