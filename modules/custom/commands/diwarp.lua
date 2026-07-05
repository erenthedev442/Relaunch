-----------------------------------
-- !diwarp
-- Warps the player to the active Domain Invasion zone (Escha - Zi'Tah or
-- Escha - Ru'Aun). If no invasion is active, warps to Zi'Tah by default.
-- Available to all players (permission 0).
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    local api = xi._domain_invasion_api
    local activeZoneId = api and api.activeZoneId and api.activeZoneId()

    if activeZoneId then
        -- Warp to the center of whichever Escha zone is under assault.
        player:setPos(0, 0, 0, 0, activeZoneId)
    else
        -- No invasion active -- send them to Zi'Tah as the default.
        player:printToPlayer('[Domain Invasion] No active invasion. Warping to Escha - Zi\'Tah.',
            xi.msg.channel.SYSTEM_3)
        player:setPos(0, 0, 0, 0, 288)  -- Escha - Zi'Tah
    end
end

return commandObj
