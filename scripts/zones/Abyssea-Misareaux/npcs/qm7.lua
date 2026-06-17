-----------------------------------
-- Zone: Abyssea-Misareaux
--  NPC: qm7 (???)
-- Spawns Nehebkau
-- !pos 321 23 -355 216
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_MISAREAUX]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.NEHEBKAU, {})
end

return entity
