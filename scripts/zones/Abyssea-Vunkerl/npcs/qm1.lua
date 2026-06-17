-----------------------------------
-- Zone: Abyssea-Vunkerl
--  NPC: qm1 (???)
-- Spawns Khalkotaur
-- !pos -115.911 -40.034 -201.988 217
-----------------------------------
local ID = zones[xi.zone.ABYSSEA_VUNKERL]
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrade = function(player, npc, trade)
end

entity.onTrigger = function(player, npc)
    xi.abyssea.qmOnTrigger(player, npc, ID.mob.KHALKOTAUR, {})
end

return entity
