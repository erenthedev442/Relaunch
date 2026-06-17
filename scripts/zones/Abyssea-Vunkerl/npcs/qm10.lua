-----------------------------------
-- Zone: Abyssea-Vunkerl
--  NPC: qm10 (???)
-- Spawns Armillaria
-- !pos -396 -31 196 217
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_VUNKERL]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.ARMILLARIA, {})
end

return entity
