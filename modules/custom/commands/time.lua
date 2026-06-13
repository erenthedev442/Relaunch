-----------------------------------
-- func: time
-- desc: Shows server time (UTC), hours until daily reset, days until
--       weekly reset (Monday 00:00 UTC), and any active seasonal event.
--
-- Usage: !time
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

local se = require('modules/custom/lua/seasonal_events')

local H = xi.msg.channel.SYSTEM_3
local B = xi.msg.channel.SYSTEM_3

commandObj.onTrigger = function(player)
    local now     = os.time()
    local utcTime = os.date('!%Y-%m-%d %H:%M UTC', now)

    -- Hours/minutes until next midnight UTC (daily board + bonus reset).
    local nextMidnight     = (math.floor(now / 86400) + 1) * 86400
    local secsUntilDaily   = nextMidnight - now
    local hoursUntilDaily  = math.floor(secsUntilDaily / 3600)
    local minsUntilDaily   = math.floor((secsUntilDaily % 3600) / 60)

    -- Days until next Monday 00:00 UTC (weekly hunt + featured reset).
    -- os.date '!%w' -> 0=Sun, 1=Mon ... 6=Sat
    local weekday         = tonumber(os.date('!%w', now)) or 0
    local daysUntilMonday = weekday == 1 and 0 or (8 - weekday) % 7

    -- Active seasonal event (if any).
    local ev = se.getActiveEvent()
    local eventStr
    if ev then
        local remaining = math.max(0, ev.finish - now)
        local days      = math.floor(remaining / 86400)
        local hours     = math.floor((remaining % 86400) / 3600)
        eventStr = string.format('  Active Event: %s  (%.1fx marks - ends in %dd %dh)',
            ev.name, ev.multiplier, days, hours)
    else
        eventStr = '  Active Event: None currently'
    end

    player:printToPlayer('[Server Time] == Current Status ===========================', H)
    player:printToPlayer(string.format('  Server time: %s', utcTime), B)
    player:printToPlayer(string.format('  Daily reset: in %dh %dm', hoursUntilDaily, minsUntilDaily), B)
    player:printToPlayer(string.format('  Weekly reset (Mon 00:00 UTC): in %d day(s)', daysUntilMonday), B)
    player:printToPlayer(eventStr, B)
    player:printToPlayer('  !featured - this week\'s bonus NMs  |  !bonus_dungeon - bonus dungeon', B)
end

return commandObj
