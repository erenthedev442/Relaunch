-----------------------------------
-- !gmjail <player> <cell 1-32> <reason>
-- Audited, online-only GM1 jail wrapper with staff protection.
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
    args = support.arguments(args, 'gmjail')
    local name, cellText, reason = (args or ''):match('^%s*(%S+)%s+(%S+)%s+(.+)$')
    local cell = tonumber(cellText)
    if not name or not cell or cell < 1 or cell > 32 then
        gm:printToPlayer('Usage: !gmjail <player> <cell 1-32> <reason>', support.channel)
        return
    end

    reason = support.requireReason(gm, reason)
    local target = support.resolvePlayer(gm, name)
    if not reason or not target then
        return
    end

    target:printToPlayer(string.format('[GM Support] You are being jailed. Reason: %s', reason), support.channel)
    require('scripts/commands/jail').onTrigger(gm, name, cell, reason)
    support.confirm(gm, target, string.format('jailed in cell %d', cell), reason)
end

return commandObj
