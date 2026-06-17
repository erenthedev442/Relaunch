-----------------------------------
-- Zone: Abyssea-Misareaux
--  NPC: qm19 (???)
-- Spawns Sobek
-- !pos 443 23 -369 216
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_MISAREAUX]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.SOBEK_OFFSET + 5, {})
end

return entity
