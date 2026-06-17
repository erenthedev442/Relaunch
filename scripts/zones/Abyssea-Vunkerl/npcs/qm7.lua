-----------------------------------
-- Zone: Abyssea-Vunkerl
--  NPC: qm7 (???)
-- Spawns Seps
-- !pos -238 -39 -717 217
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_VUNKERL]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.SEPS, {})
end

return entity
