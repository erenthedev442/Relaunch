-----------------------------------
-- Zone: Abyssea-Vunkerl
--  NPC: qm19 (???)
-- Spawns Durinn
-- !pos -555 -47 -564 217
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_VUNKERL]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.DURINN_OFFSET + 4, {})
end

return entity
