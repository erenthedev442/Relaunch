-----------------------------------
-- Zone: Abyssea-Misareaux
--  NPC: qm18 (???)
-- Spawns Amhuluk
-- !pos 14 -16 -50 216
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_MISAREAUX]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.AMHULUK_OFFSET + 5, {})
end

return entity
