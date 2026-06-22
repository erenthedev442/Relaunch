-----------------------------------
-- Zone: Abyssea-Uleguerand
--  NPC: qm21 (???)
-- Spawns Isgebind
-- !pos 145 -117 471 253
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_ULEGUERAND]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.ISGEBIND_OFFSET + 8, {})
end

return entity
