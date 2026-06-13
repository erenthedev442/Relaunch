-----------------------------------
-- func: events
-- desc: Lists upcoming and active seasonal bonus mark events from the
--       catalog.  Shows event name, multiplier, start/end dates, and
--       status (active / upcoming / expired).
--
-- Usage: !events
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

local H = xi.msg.channel.SYSTEM_3
local B = xi.msg.channel.SYSTEM_3

-- Load both the static catalog and the dynamic events file (written by
-- !setbonus). The dynamic file is optional - missing it is not an error.
local staticCatalog = require('modules/custom/lua/seasonal_events_catalog')

local function getDynamicEvents()
    local ok, fn = pcall(loadfile, 'modules/custom/lua/seasonal_events_dynamic.lua')
    if not ok or not fn then return {} end
    local ok2, events = pcall(fn)
    return (ok2 and type(events) == 'table') and events or {}
end

commandObj.onTrigger = function(player)
    local now    = os.time()
    local all    = {}

    -- Merge static + dynamic events into one list.
    for _, ev in ipairs(staticCatalog.events or {}) do
        table.insert(all, ev)
    end
    for _, ev in ipairs(getDynamicEvents()) do
        table.insert(all, ev)
    end

    player:printToPlayer('[Events] == Seasonal Bonus Events ====================', H)

    if #all == 0 then
        player:printToPlayer('  No events scheduled.  Check back soon!', B)
        return
    end

    -- Sort: active first, then upcoming by start date.
    table.sort(all, function(a, b)
        local aActive = (now >= a.start and now < a.finish)
        local bActive = (now >= b.start and now < b.finish)
        if aActive ~= bActive then return aActive end  -- active before upcoming
        return a.start < b.start
    end)

    local shown = 0
    for _, ev in ipairs(all) do
        -- Skip events that have already ended.
        if ev.finish <= now then goto continue end

        local status
        if now >= ev.start and now < ev.finish then
            local remaining = ev.finish - now
            local days  = math.floor(remaining / 86400)
            local hours = math.floor((remaining % 86400) / 3600)
            status = string.format('ACTIVE  (ends in %dd %dh)', days, hours)
        else
            local startIn = ev.start - now
            local days  = math.floor(startIn / 86400)
            local hours = math.floor((startIn % 86400) / 3600)
            status = string.format('upcoming in %dd %dh', days, hours)
        end

        player:printToPlayer(
            string.format('  %-26s  x%.1f marks  [%s]', ev.name, ev.multiplier, status), B)
        shown = shown + 1
        ::continue::
    end

    if shown == 0 then
        player:printToPlayer('  No upcoming events at this time.  Check back soon!', B)
    end

    player:printToPlayer('  !time - server time  |  !featured - weekly bonus NMs', B)
end

return commandObj
