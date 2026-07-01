-----------------------------------
-- !invasion [start | end | status]
-- GM command to manually trigger or abort the GM Home invasion event.
-- Requires gmlevel >= 4.
--
--   !invasion         -- show current status
--   !invasion start   -- force-start (GM must be standing in GM Home)
--   !invasion end     -- abort active invasion and despawn all mobs
-----------------------------------
local commandObject = {}
local catalog = require('modules/custom/lua/invasion_catalog')

commandObject.cmdprops = {
    permission = 1,
    parameters = 's',
}

commandObject.onUseCommand = function(player, params)
    local api = xi._invasion_api
    if not api then
        player:printToPlayer('[Invasion] System not loaded - check modules/custom/lua/Invasion.lua.')
        return
    end

    local sub = (params[1] or ''):lower()

    if sub == 'start' then
        if player:getZoneID() ~= catalog.zoneId then
            player:printToPlayer(string.format(
                '[Invasion] You must be in GM Home (zone %d) to start the invasion.',
                catalog.zoneId))
            return
        end
        local ok, err = api.forceStart(player:getZone())
        if ok then
            player:printToPlayer('[Invasion] Invasion force-started.')
        else
            player:printToPlayer('[Invasion] ' .. tostring(err))
        end

    elseif sub == 'end' or sub == 'stop' then
        local ok, err = api.forceEnd()
        if ok then
            player:printToPlayer('[Invasion] Invasion aborted - all Voidsent despawned.')
        else
            player:printToPlayer('[Invasion] ' .. tostring(err))
        end

    else
        local info = api.info()
        if not info then
            player:printToPlayer('[Invasion] No active invasion. Use: !invasion start (in GM Home) or !invasion end')
        else
            local rem = math.max(0, info.endsAt - os.time())
            player:printToPlayer(string.format(
                '[Invasion] Active: Wave %d/%d | %dm %ds remaining.',
                info.wave, info.total,
                math.floor(rem / 60), rem % 60))
        end
    end
end

return commandObject
