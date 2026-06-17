-----------------------------------
-- Zone: Abyssea-Misareaux
--  NPC: qm22 (???)
-- Spawns Amhuluk
-- !pos 0 -15 -34 216
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_MISAREAUX]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.AMHULUK_OFFSET + 10, {})
end

return entity
