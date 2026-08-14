-----------------------------------
-- !gmpardon <player> <reason>
-- Audited, online-only GM1 pardon wrapper with staff protection.
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
    args = support.arguments(args, 'gmpardon')
    local name, reason = (args or ''):match('^%s*(%S+)%s+(.+)$')
    if not name then
        gm:printToPlayer('Usage: !gmpardon <player> <reason>', support.channel)
        return
    end

    reason = support.requireReason(gm, reason)
    local target = support.resolvePlayer(gm, name)
    if not reason or not target then
        return
    end

    if (target:getCharVar('inJail') or 0) == 0 then
        gm:printToPlayer(string.format('[GM Pardon] %s is not jailed.', target:getName()), support.channel)
        return
    end

    require('scripts/commands/pardon').onTrigger(gm, name)
    target:printToPlayer(string.format('[GM Support] You were pardoned. Reason: %s', reason), support.channel)
    support.confirm(gm, target, 'pardoned from jail', reason)
end

return commandObj
