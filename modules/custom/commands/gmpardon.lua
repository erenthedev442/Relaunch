-----------------------------------
-- !gmpardon <player> <reason>
-- Audited GM1 pardon wrapper. Online or offline. Staff protection.
-----------------------------------
local support = require('modules/custom/lua/gm_support')
local jail = require('modules/custom/lua/mordion_jail')

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
    if not reason then
        return
    end

    local target = GetPlayerByName(name)
    if target then
        if (target:getGMLevel() or 0) > 0 then
            gm:printToPlayer('[GM Support] GM1 tools cannot modify another staff character.', support.channel)
            return
        end

        if not jail.isJailedPlayer(target) then
            gm:printToPlayer(string.format('[GM Pardon] %s is not jailed.', target:getName()), support.channel)
            return
        end

        target:printToPlayer(string.format('[GM Support] You were pardoned. Reason: %s', reason), support.channel)
        require('scripts/commands/pardon').onTrigger(gm, name)
        support.confirm(gm, target, 'pardoned from jail', reason)
        return
    end

    local playerId = GetPlayerIDByName(name)
    if
        playerId == nil or
        playerId <= 0 or
        playerId >= 0xFFFFFFFF
    then
        gm:printToPlayer(string.format('[GM Support] %s was not found.', name), support.channel)
        return
    end

    if PlayerHasValidSession(playerId) then
        gm:printToPlayer(
            string.format('[GM Support] %s is online on another map process. Move to that cluster first.', name),
            support.channel)
        return
    end

    if not jail.isJailedVar(GetCharVar(playerId, 'inJail')) then
        gm:printToPlayer(string.format('[GM Pardon] %s is not jailed.', name), support.channel)
        return
    end

    require('scripts/commands/pardon').onTrigger(gm, name)
    support.confirmName(gm, name, 'pardoned from jail (offline)', reason)
end

return commandObj
