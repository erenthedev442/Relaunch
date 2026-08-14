-----------------------------------
-- !diwarp
-- Explicitly opts the player into the active/mustering Domain Invasion and
-- warps them to that zone's isolated rally point.
-- Available to all players (permission 0).
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = '',
}

commandObj.onTrigger = function(player)
    local api = xi._domain_invasion_api
    if not api or not api.volunteer then
        player:printToPlayer('[Domain Invasion] The event service is unavailable.',
            xi.msg.channel.SYSTEM_3)
        return
    end

    local ok, zoneId, rally, label = api.volunteer(player)
    if not ok then
        player:printToPlayer('[Domain Invasion] ' .. tostring(zoneId),
            xi.msg.channel.SYSTEM_3)
        return
    end

    player:printToPlayer(
        string.format('[Domain Invasion] You have opted in to defend %s.', label),
        xi.msg.channel.SYSTEM_3)
    player:setPos(rally.x, rally.y, rally.z, rally.rot or 0, zoneId)
end

return commandObj
