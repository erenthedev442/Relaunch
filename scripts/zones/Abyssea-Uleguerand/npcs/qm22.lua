-----------------------------------
-- Zone: Abyssea-Uleguerand
--  NPC: qm22 (???)
-- Spawns Resheph
-- !pos 409 -51 163 253
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_ULEGUERAND]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.RESHEPH_OFFSET + 8, {})
end

return entity
