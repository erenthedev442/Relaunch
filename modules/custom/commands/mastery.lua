-----------------------------------
-- !mastery [abort | status | grant <weapon> [player] | reset <player>]
--
--   !mastery                 show your Trial 4 progress (all players)
--   !mastery abort           end your active guardian challenge (no reward)
--   !mastery status          GM (5): list all active challenge sessions
--   !mastery grant <w> [p]   GM (5): grant PW_T4_<weapon>_Done to self or <p>
--   !mastery reset [p]       GM (5): clear all mastery charVars for self or <p>
--
-- Reads runtime state from xi._jm_* globals set by job_mastery.lua.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 'sss',
}

local masteryCatalog = require('modules/custom/lua/weapon_mastery_catalog')
local GUARDIAN_ORDER = masteryCatalog.order

local function sessions()   return xi._jm_sessions  end
local function guardians()  return xi._jm_guardians  end
local function doEnd(p, r)
    if xi._jm_endChallenge then xi._jm_endChallenge(p, r)
    else p:printToPlayer('[Mastery] Module not loaded.', xi.msg.channel.SYSTEM_3) end
end

local function printStatus(player, target)
    local G = guardians()
    if not G then
        player:printToPlayer('[Mastery] Module not loaded.', xi.msg.channel.SYSTEM_3)
        return
    end
    local done, pending = {}, {}
    for _, key in ipairs(GUARDIAN_ORDER) do
        if masteryCatalog.isComplete(target, key) then
            done[#done + 1] = G[key].label
        else
            pending[#pending + 1] = G[key].label
        end
    end
    local t4 = (target:getCharVar('PW_Trial4_Done') or 0) == 1
    player:printToPlayer(string.format('[Mastery] %s — Trial 4: %s',
        target:getName(), t4 and 'COMPLETE' or 'pending'), xi.msg.channel.SYSTEM_3)
    if #done > 0 then
        player:printToPlayer('[Mastery] Done: ' .. table.concat(done, ', '), xi.msg.channel.SYSTEM_3)
    end
    if #pending > 0 then
        player:printToPlayer('[Mastery] Pending: ' .. table.concat(pending, ', '), xi.msg.channel.SYSTEM_3)
    end
end

commandObj.onTrigger = function(player, sub, arg2, arg3)
    sub = (sub or ''):lower()

    -- abort — any player can abort their own run
    if sub == 'abort' then
        local sess = sessions()
        if not sess or not sess[player:getName()] then
            player:printToPlayer('[Mastery] No active challenge.', xi.msg.channel.SYSTEM_3)
            return
        end
        doEnd(player, 'abort')
        return
    end

    -- no args — self-status for any player
    if sub == '' then
        printStatus(player, player)
        return
    end

    -- GM-only below
    if player:getGMLevel() < 5 then
        player:printToPlayer('[Mastery] Permission denied.', xi.msg.channel.SYSTEM_3)
        return
    end

    if sub == 'status' then
        local sess = sessions()
        if not sess then
            player:printToPlayer('[Mastery] Module not loaded.', xi.msg.channel.SYSTEM_3)
            return
        end
        local count = 0
        for name, s in pairs(sess) do
            player:printToPlayer(string.format('[Mastery] %s: weapon=%s boss=%s',
                name, s.weapon or '?', s.boss and 'alive' or 'none'), xi.msg.channel.SYSTEM_3)
            count = count + 1
        end
        if count == 0 then player:printToPlayer('[Mastery] No active sessions.', xi.msg.channel.SYSTEM_3) end

    elseif sub == 'grant' then
        local weapon = arg2 and arg2:lower() or nil
        local G = guardians()
        if not weapon or not G or not G[weapon] then
            player:printToPlayer('[Mastery] Usage: !mastery grant <weapon> [player]', xi.msg.channel.SYSTEM_3)
            player:printToPlayer('[Mastery] Weapons: ' .. table.concat(GUARDIAN_ORDER, ', '), xi.msg.channel.SYSTEM_3)
            return
        end
        local target = arg3 and GetPlayerByName(arg3) or player
        if not target then
            player:printToPlayer('[Mastery] Player not found: ' .. arg3, xi.msg.channel.SYSTEM_3)
            return
        end
        target:setCharVar(masteryCatalog.completionVar(weapon), 1)
        if (target:getCharVar('PW_Trial4_Done') or 0) == 0 then
            target:setCharVar('PW_Trial4_Done', 1)
        end
        player:printToPlayer(string.format('[Mastery] Granted %s to %s.', weapon, target:getName()), xi.msg.channel.SYSTEM_3)

    elseif sub == 'reset' then
        local target = arg2 and GetPlayerByName(arg2) or player
        if not target then
            player:printToPlayer('[Mastery] Player not found: ' .. (arg2 or '?'), xi.msg.channel.SYSTEM_3)
            return
        end
        local sess = sessions()
        if sess and sess[target:getName()] then doEnd(target, 'abort') end
        for _, key in ipairs(GUARDIAN_ORDER) do
            target:setCharVar(masteryCatalog.completionVar(key), 0)
        end
        target:setCharVar('PW_Trial4_Done', 0)
        player:printToPlayer('[Mastery] All Trial 4 progress cleared for ' .. target:getName(), xi.msg.channel.SYSTEM_3)

    else
        player:printToPlayer('[Mastery] Sub-cmds: abort | status | grant <weapon> [player] | reset [player]', xi.msg.channel.SYSTEM_3)
    end
end

return commandObj
