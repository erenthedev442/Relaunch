-----------------------------------
-- !iwarp
-- Warps the player straight to the invasion spawn plaza in Al Zahbi.
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
    -- Default closed for launch when Invasion.lua is not loaded yet / retired.
    local api = xi._invasion_api
    if not api or not api.isRetired or api.isRetired() then
        player:printToPlayer('[Invasion] Al Zahbi Invasion is disabled for launch.',
            xi.msg.channel.SYSTEM_3)
        return
    end

    -- Drop the player straight onto the invasion battleground. Pull the exact
    -- spot from invasion_catalog.fixedSpawn so this stays in sync if the
    -- invasion ever relocates again (fallback = the Al Zahbi market plaza).
    local ok, catalog = pcall(require, 'modules/custom/lua/invasion_catalog')
    if ok and catalog and catalog.fixedSpawn and catalog.zoneId then
        local fs = catalog.fixedSpawn
        player:setPos(fs.x, fs.y, fs.z, 0, catalog.zoneId)
    else
        player:setPos(42.4, 0, 46.4, 0, xi.zone.AL_ZAHBI)
    end
end

return commandObj
