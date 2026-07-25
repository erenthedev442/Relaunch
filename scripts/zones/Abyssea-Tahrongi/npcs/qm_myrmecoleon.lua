-----------------------------------
-- Zone: Abyssea-Tahrongi
--  NPC: qm_myrmecoleon (???)
-- Spawns Myrmecoleon
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_TAHRONGI]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.MYRMECOLEON, {}, {})
end

return entity
