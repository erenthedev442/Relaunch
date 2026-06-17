-----------------------------------
-- Zone: Abyssea-Misareaux
--  NPC: qm4 (???)
-- Spawns Manohra
-- !pos 121 -8 -120 216
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_MISAREAUX]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.MANOHRA, {})
end

return entity
