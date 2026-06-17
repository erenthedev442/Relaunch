-----------------------------------
-- Zone: Abyssea-Misareaux
--  NPC: qm14 (???)
-- Spawns Amhuluk
-- !pos 0 -16 -50 216
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_MISAREAUX]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.AMHULUK_OFFSET + 0, {})
end

return entity
