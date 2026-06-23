-----------------------------------
-- func: despawnzone [zoneId]
-- desc: Despawns all mobs in a zone (default: GM's current zone).
--       !despawnzone          -- clears your current zone
--       !despawnzone 278      -- clears Gwora Corridor (Reforge zone)
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 2,
    parameters = 'i'
}

commandObj.onTrigger = function(player, zoneId)
    local targetZoneId = zoneId or player:getZoneID()
    local zone = GetZone(targetZoneId)
    if zone == nil then
        player:printToPlayer(string.format('Invalid zone ID: %d', targetZoneId))
        return
    end

    local mobs = zone:getMobs()
    local count = 0
    for _, mob in pairs(mobs) do
        DespawnMob(mob:getID())
        count = count + 1
    end

    player:printToPlayer(string.format('[despawnzone] Despawned %d mob(s) in zone %d (%s).',
        count, targetZoneId, zone:getName()))
end

return commandObj
