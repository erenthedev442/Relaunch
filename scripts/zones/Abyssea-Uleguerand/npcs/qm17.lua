-----------------------------------
-- Zone: Abyssea-Uleguerand
--  NPC: qm17 (???)
-- Spawns Isgebind
-- !pos 175 -113 472 253
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_ULEGUERAND]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.ISGEBIND_OFFSET + 4, {})
end

return entity
