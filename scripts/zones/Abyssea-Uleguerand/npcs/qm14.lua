-----------------------------------
-- Zone: Abyssea-Uleguerand
--  NPC: qm14 (???)
-- Spawns Resheph
-- !pos 422 -51 156 253
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_ULEGUERAND]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.RESHEPH_OFFSET + 0, {})
end

return entity
