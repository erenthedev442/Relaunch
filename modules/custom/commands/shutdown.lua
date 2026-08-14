-----------------------------------
-- func: shutdown
-- desc: GM command. Broadcasts a countdown warning to all zones before
--       a planned server restart.  The actual restart is performed by
--       the admin; this command only handles the in-game announcement.
--
-- Usage (GM only):
--   !shutdown        - 5-minute warning (default)
--   !shutdown 10     - 10-minute warning
--   !shutdown 1      - 1-minute warning
--
-- Clamped to 1-60 minutes.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 5,   -- Owner/developer GM only
    parameters = 'i',
}

commandObj.onTrigger = function(player, minutes)
    minutes = tonumber(minutes) or 5
    minutes = math.max(1, math.min(60, minutes))

    local function broadcast(msg)
        player:printToArea(msg, xi.msg.channel.SYSTEM_3, xi.msg.area.SYSTEM, '', true)
    end

    -- Immediate announcement.
    broadcast(string.format(
        '[NOTICE] * Server restart in %d minute(s). Please find a safe spot and log out. Thank you!',
        minutes))

    -- Mid-point warning (if there's enough runway for it to be useful).
    if minutes >= 4 then
        local halfMs = math.floor(minutes / 2) * 60000
        player:timer(halfMs, function(p)
            local remaining = minutes - math.floor(minutes / 2)
            p:printToArea(
                string.format('[NOTICE] Server restart in %d minute(s). Please log out soon!', remaining),
                xi.msg.channel.SYSTEM_3, xi.msg.area.SYSTEM, '', true)
        end)
    end

    -- 1-minute final warning (only if we started with > 1 minute).
    if minutes > 1 then
        player:timer((minutes - 1) * 60000, function(p)
            p:printToArea(
                '[NOTICE] * Server restart in 1 minute - last call! Please log out now!',
                xi.msg.channel.SYSTEM_3, xi.msg.area.SYSTEM, '', true)
        end)
    end

    -- Confirmation to the GM who ran the command.
    player:printToPlayer(
        string.format('[Shutdown] Countdown started: %d minute(s). Broadcasts scheduled.', minutes),
        xi.msg.channel.SYSTEM_3)
end

return commandObj
