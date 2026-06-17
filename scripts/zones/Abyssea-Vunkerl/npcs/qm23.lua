-----------------------------------
-- Zone: Abyssea-Vunkerl
--  NPC: qm23 (???)
-- Spawns Durinn
-- !pos -571 -47 -570 217
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_VUNKERL]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.DURINN_OFFSET + 8, {})
end

return entity
