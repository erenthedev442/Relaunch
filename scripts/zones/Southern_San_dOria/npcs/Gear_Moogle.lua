-----------------------------------
-- Gear_Moogle.lua
-- Retired starter-kit NPC. The custom Gear Moogle row is deleted in
-- modules/custom/sql/gear_moogle.sql; this script stays as a no-op in case
-- the NPC is ever re-added.
-----------------------------------
---@type TNpcEntity
local entity = {}

entity.onTrigger = function(player, npc)
    player:printToPlayer('The Gear Moogle is not available on this server.', xi.msg.channel.SYSTEM_3)
end

return entity
