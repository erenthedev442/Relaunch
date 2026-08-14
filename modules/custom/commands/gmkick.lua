-----------------------------------
-- !gmkick <player> <reason>
-- Audited support disconnect without jail or account mutation.
-----------------------------------
local support = require('modules/custom/lua/gm_support')

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = 'b',
}

commandObj.onTrigger = function(gm, args)
    args = support.arguments(args, 'gmkick')
    local name, reason = (args or ''):match('^%s*(%S+)%s+(.+)$')
    if not name then
        gm:printToPlayer('Usage: !gmkick <player> <reason>', support.channel)
        return
    end

    reason = support.requireReason(gm, reason)
    local target = support.resolvePlayer(gm, name)
    if not reason or not target then
        return
    end

    target:printToPlayer(
        string.format('[GM Support] You are being disconnected. Reason: %s', reason),
        support.channel)
    support.confirm(gm, target, 'disconnect requested', reason)
    target:timer(1000, function(player)
        player:leaveGame()
    end)
end

return commandObj
