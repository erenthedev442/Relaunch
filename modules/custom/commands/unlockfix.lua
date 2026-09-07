-----------------------------------
-- !unlockfix <player> <reason>
-- GM1: force-rerun first-login unlocks for an online player.
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
    args = support.arguments(args, 'unlockfix')
    local name, reason = (args or ''):match('^%s*(%S+)%s+(.+)$')
    if not name then
        gm:printToPlayer('Usage: !unlockfix <player> <reason>', support.channel)
        return
    end

    reason = support.requireReason(gm, reason)
    if not reason then
        return
    end

    local online = GetPlayerByName(name)
    local target
    if online and gm.getID and online.getID and online:getID() == gm:getID() then
        target = online
    else
        target = support.resolvePlayer(gm, name)
    end

    if not target then
        return
    end

    local upgrade = xi.characterUpgrade
    if not upgrade or not upgrade.resume then
        gm:printToPlayer('[GM Support] Character setup module is not loaded.', support.channel)
        return
    end

    upgrade.resume(target, { force = true, delayMs = 500 })
    target:printToPlayer(
        string.format('[GM Support] Character setup was re-run. Reason: %s', reason),
        support.channel)
    support.confirm(gm, target, 'first-login unlocks re-run', reason)
end

return commandObj
