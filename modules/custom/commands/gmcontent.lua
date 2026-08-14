-----------------------------------
-- !gmcontent status <player>
-- !gmcontent reset <system> <player> <reason>
-- Safe, audited session cleanup; never grants completion or rewards.
-----------------------------------
local support = require('modules/custom/lua/gm_support')
local dungeonRuntime = require('modules/custom/lua/dungeon_instance')

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = 'b',
}

local SYSTEMS = 'dungeon|wave|tower|gauntlet|apex|trial'

local function usage(gm)
    gm:printToPlayer('Usage: !gmcontent status <player>', support.channel)
    gm:printToPlayer(
        string.format('       !gmcontent reset <%s> <player> <reason>', SYSTEMS),
        support.channel)
end

local function printStatus(gm, target)
    local name = target:getName()
    gm:printToPlayer(string.format(
        '[GM Content] %s: dungeon=%s wave=%s tower=%s gauntlet=%s apex=%s trial=%s',
        name,
        ((target:getCharVar('DungeonActive') or 0) > 0 or target:getInstance() ~= nil) and 'active' or '-',
        (xi._gm_sessions and xi._gm_sessions[name]) and 'active' or '-',
        (xi._et_sessions and xi._et_sessions[name]) and 'active' or '-',
        (xi._gauntlet_sessions and xi._gauntlet_sessions[name]) and 'active' or '-',
        (xi._apex_sessions and xi._apex_sessions[name]) and 'active' or '-',
        (xi._prestige_summonedTrial and xi._prestige_summonedTrial[target:getID()]) and 'active' or '-'),
        support.channel)
end

local function resetSystem(gm, target, system)
    local name = target:getName()

    if system == 'dungeon' then
        local closed, _, _, err = dungeonRuntime.forceClose(target)
        return closed, err or 'private dungeon closed'
    elseif system == 'wave' then
        if not (xi._gm_sessions and xi._gm_sessions[name]) then
            return false, 'no active Wave Master session'
        end
        if xi._gm_endSession then
            xi._gm_endSession(target, false)
        else
            xi._gm_sessions[name] = nil
        end
        return true, 'Wave Master session aborted'
    elseif system == 'tower' then
        if not (xi._et_sessions and xi._et_sessions[name]) or not xi._et_endTower then
            return false, 'no active Tower session'
        end
        xi._et_endTower(target, 'abort')
        return true, 'Tower session aborted'
    elseif system == 'gauntlet' then
        if not (xi._gauntlet_sessions and xi._gauntlet_sessions[name]) or not xi._gauntlet_endRun then
            return false, 'no active Gauntlet session'
        end
        xi._gauntlet_endRun(target, 'abort')
        return true, 'Gauntlet session aborted'
    elseif system == 'apex' then
        if not (xi._apex_sessions and xi._apex_sessions[name]) or not xi._apex_endRun then
            return false, 'no active Apex session'
        end
        xi._apex_endRun(target, 'abort')
        return true, 'Apex session aborted'
    elseif system == 'trial' then
        if not (xi._prestige_summonedTrial and xi._prestige_summonedTrial[target:getID()]) then
            return false, 'no active Ascension trial flag'
        end
        xi._prestige_summonedTrial[target:getID()] = nil
        return true, 'Ascension trial state reset'
    end

    return false, 'unknown system'
end

commandObj.onTrigger = function(gm, args)
    args = support.arguments(args, 'gmcontent')
    local action = (args or ''):match('^%s*(%S+)')

    if action == 'status' then
        local name = args:match('^%s*status%s+(%S+)%s*$')
        local target = support.resolvePlayer(gm, name)
        if not target then
            usage(gm)
            return
        end
        printStatus(gm, target)
        return
    end

    if action ~= 'reset' then
        usage(gm)
        return
    end

    local system, name, reason = args:match('^%s*reset%s+(%S+)%s+(%S+)%s+(.+)$')
    reason = support.requireReason(gm, reason)
    local target = support.resolvePlayer(gm, name)
    if not system or not reason or not target then
        usage(gm)
        return
    end

    system = system:lower()
    local ok, message = resetSystem(gm, target, system)
    if not ok then
        gm:printToPlayer(string.format('[GM Content] %s: %s.', target:getName(), message), support.channel)
        return
    end

    target:printToPlayer(
        string.format('[GM Support] %s. Reason: %s', message, reason),
        support.channel)
    support.confirm(gm, target, message, reason)
end

return commandObj
