-----------------------------------
-- Zone: Abyssea-Misareaux
--  NPC: qm3 (???)
-- Spawns Funereal Apkallu
-- !pos 209 -23 321 216
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_MISAREAUX]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.FUNEREAL_APKALLU, {})
end

return entity
