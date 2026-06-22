-----------------------------------
-- Zone: Abyssea-Uleguerand
--  NPC: qm19 (???)
-- Spawns Pantokrator
-- !pos -199 -175 170 253
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_ULEGUERAND]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.PANTOKRATOR_OFFSET + 8, {})
end

return entity
