-----------------------------------
-- Zone: Abyssea-Uleguerand
--  NPC: qm7 (???)
-- Spawns Veri Selen
-- !pos 13 -140 470 253
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_ULEGUERAND]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.VERI_SELEN, {})
end

return entity
