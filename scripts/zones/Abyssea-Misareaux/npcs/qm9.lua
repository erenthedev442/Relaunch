-----------------------------------
-- Zone: Abyssea-Misareaux
--  NPC: qm9 (???)
-- Spawns Karkatakam
-- !pos 200 -15 519 216
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_MISAREAUX]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.KARKATAKAM, {})
end

return entity
