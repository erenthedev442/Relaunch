-----------------------------------
-- !gmrelease <player> <reason>
-- Gentle, audited event-state recovery for an online player.
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
    args = support.arguments(args, 'gmrelease')
    local name, reason = (args or ''):match('^%s*(%S+)%s+(.+)$')
    if not name then
        gm:printToPlayer('Usage: !gmrelease <player> <reason>', support.channel)
        return
    end

    reason = support.requireReason(gm, reason)
    local target = support.resolvePlayer(gm, name)
    if not reason or not target then
        return
    end

    target:release()
    target:setPos(target:getXPos(), target:getYPos(), target:getZPos(), target:getRotPos())
    target:printToPlayer(
        string.format('[GM Support] Your event state was released. Reason: %s', reason),
        support.channel)
    support.confirm(gm, target, 'event state released and position resynced', reason)
end

return commandObj
