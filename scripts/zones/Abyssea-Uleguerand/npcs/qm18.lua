-----------------------------------
-- Zone: Abyssea-Uleguerand
--  NPC: qm18 (???)
-- Spawns Resheph
-- !pos 433 -51 145 253
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_ULEGUERAND]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.RESHEPH_OFFSET + 4, {})
end

return entity
