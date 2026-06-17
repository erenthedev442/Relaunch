-----------------------------------
-- Zone: Abyssea-Misareaux
--  NPC: qm8 (???)
-- Spawns Avalerion
-- !pos 41 -16 81 216
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_MISAREAUX]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.AVALERION, {})
end

return entity
