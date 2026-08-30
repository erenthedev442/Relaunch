-----------------------------------
-- Area: VeLugannon Palace
--  NPC: qm2 (???)
-- Note: Flavor ???. Brigandish Blade is a 30-minute Hunt Guild camp.
-- !pos 0.1 0.1 -286 177
-----------------------------------
local ID = zones[xi.zone.VELUGANNON_PALACE]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    player:messageSpecial(ID.text.EVIL_PRESENCE)
end

return entity
