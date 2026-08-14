-----------------------------------
-- Shared safeguards for GM1 support commands.
-----------------------------------
local support = {}

support.channel = xi.msg.channel.SYSTEM_3

function support.arguments(commandLine, commandName)
    return (commandLine or ''):gsub('^' .. commandName .. '%s*', '', 1)
end

function support.resolvePlayer(gm, name)
    if not name or name == '' then
        gm:printToPlayer('[GM Support] A player name is required.', support.channel)
        return nil
    end

    local target = GetPlayerByName(name)
    if not target then
        local playerId = GetPlayerIDByName(name)
        if playerId and playerId > 0 and playerId < 0xFFFFFFFF and PlayerHasValidSession(playerId) then
            gm:printToPlayer(
                string.format('[GM Support] %s is online on another map process. Move to that cluster first.', name),
                support.channel)
        else
            gm:printToPlayer(string.format('[GM Support] %s is not online.', name), support.channel)
        end
        return nil
    end

    if (target:getGMLevel() or 0) > 0 then
        gm:printToPlayer('[GM Support] GM1 tools cannot modify another staff character.', support.channel)
        return nil
    end

    return target
end

function support.requireReason(gm, reason)
    reason = (reason or ''):match('^%s*(.-)%s*$')
    if reason == '' then
        gm:printToPlayer('[GM Support] A reason is required for the audit log.', support.channel)
        return nil
    end

    return reason
end

function support.confirm(gm, target, action, reason)
    gm:printToPlayer(
        string.format('[GM Support] %s: %s. Reason: %s', target:getName(), action, reason),
        support.channel)
end

return support
