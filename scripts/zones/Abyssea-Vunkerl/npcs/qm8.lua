-----------------------------------
-- Zone: Abyssea-Vunkerl
--  NPC: qm8 (???)
-- Spawns Xan
-- !pos 120 -39 -551 217
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_VUNKERL]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.XAN, {})
end

return entity
