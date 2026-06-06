-----------------------------------
-- func: setbonus
-- desc: GM command.  Activates a temporary marks multiplier server-wide
--       without editing the seasonal_events_catalog.  Writes to
--       seasonal_events_dynamic.lua; seasonal_events.lua picks it up
--       within 60 seconds via its loadfile TTL cache.
--
-- Usage (GM only):
--   !setbonus <multiplier> <hours>
--   !setbonus 2 4    - 2x marks for 4 hours
--   !setbonus 1.5 24 - 1.5x marks for 24 hours
--   !setbonus 1 0    - immediately cancels any active dynamic event
--
-- Multiplier: 1.0 - 5.0  (1.0 effectively disables/cancels)
-- Duration:   1 - 168 hours (1 week max)
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,   -- GM only
    parameters = 's', -- parsed as string so we can handle "2 4" together
}

local DYNAMIC_PATH = 'modules/custom/lua/seasonal_events_dynamic.lua'

commandObj.onTrigger = function(player, args)
    -- Parse "multiplier hours" from the single string parameter.
    local multStr, hoursStr = (args or ''):match('^%s*([%d%.]+)%s+([%d%.]+)%s*$')
    if not multStr then
        player:printToPlayer(
            '[setbonus] Usage: !setbonus <multiplier> <hours>  e.g. !setbonus 2 4',
            xi.msg.channel.SYSTEM_3)
        return
    end

    local multiplier = math.max(1.0, math.min(5.0, tonumber(multStr) or 2.0))
    local hours      = math.max(0,  math.min(168,  math.floor(tonumber(hoursStr) or 2)))

    -- hours = 0 is a cancel: write an empty file.
    local now    = os.time()
    local finish = now + hours * 3600

    local f = io.open(DYNAMIC_PATH, 'w')
    if not f then
        player:printToPlayer(
            string.format('[setbonus] ERROR: could not write to %s', DYNAMIC_PATH),
            xi.msg.channel.SYSTEM_3)
        return
    end

    if hours == 0 or multiplier <= 1.0 then
        -- Cancel: write empty table.
        f:write('-- seasonal_events_dynamic.lua (cleared by !setbonus)\nreturn {}\n')
        f:close()
        player:printToPlayer('[setbonus] Dynamic bonus event cancelled.', xi.msg.channel.SYSTEM_3)
        player:printToArea(
            '[Event] The GM bonus event has ended.',
            xi.msg.channel.SYSTEM_3, xi.msg.area.SYSTEM, '', true)
        return
    end

    f:write(string.format(
        '-- seasonal_events_dynamic.lua\n' ..
        '-- Written by !setbonus on %s UTC  (expires %s UTC)\n' ..
        'return {\n' ..
        '    {\n' ..
        '        name       = \'GM Bonus Event\',\n' ..
        '        multiplier = %.2f,\n' ..
        '        start      = %d,\n' ..
        '        finish     = %d,\n' ..
        '        priority   = 99,\n' ..
        '    },\n' ..
        '}\n',
        os.date('!%%Y-%%m-%%d %%H:%%M', now),
        os.date('!%%Y-%%m-%%d %%H:%%M', finish),
        multiplier, now, finish))
    f:close()

    -- Server-wide announcement.
    local broadcastMsg = string.format(
        '[Event] \xe2\x98\x85 GM Bonus: %.1fx Hunt Marks for the next %d hour(s)!  Happy hunting!',
        multiplier, hours)
    player:printToArea(broadcastMsg, xi.msg.channel.SYSTEM_3, xi.msg.area.SYSTEM, '', true)

    -- GM confirmation.
    player:printToPlayer(
        string.format('[setbonus] %.1fx bonus active for %d hour(s).  Picks up within 60s.',
            multiplier, hours),
        xi.msg.channel.SYSTEM_3)
    player:printToPlayer(
        string.format('[setbonus] Cancel with:  !setbonus 1 0', ''),
        xi.msg.channel.SYSTEM_3)
end

return commandObj
