-----------------------------------
-- !tower [abort | status | tp <player> | floor <N>]
--
--   !tower              show your current run status (or "not in a run")
--   !tower abort        end your current run immediately (warp back, no reward)
--   !tower status       GM only: show all active sessions
--   !tower tp <name>    GM only (perm 4): warp a stuck player out
--   !tower floor <N>    GM only (perm 4): skip the target player to floor N
--
-- Runtime state lives in xi._et (set by endless_tower.lua).
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 'ss',
}

local function getSessions()
    return xi._et_sessions
end

local function endTowerFor(player, reason)
    if xi._et_endTower then
        xi._et_endTower(player, reason)
    else
        player:printToPlayer('[Tower] Internal error: Tower module not loaded.', xi.msg.channel.SYSTEM_3)
    end
end

commandObj.onTrigger = function(player, sub, arg2)
    sub = (sub or ''):lower()

    -- Player-level: abort own run.
    if sub == 'abort' then
        local sessions = getSessions()
        if not sessions then
            player:printToPlayer('[Tower] Tower module not loaded.', xi.msg.channel.SYSTEM_3)
            return
        end
        if not sessions[player:getName()] then
            player:printToPlayer('[Tower] You are not in a Tower run.', xi.msg.channel.SYSTEM_3)
            return
        end
        endTowerFor(player, 'abort')
        return
    end

    -- Player-level: own status.
    if sub == '' or sub == 'status' and player:getGMLevel() < 4 then
        local sessions = getSessions()
        if not sessions then
            player:printToPlayer('[Tower] Tower module not loaded.', xi.msg.channel.SYSTEM_3)
            return
        end
        local sess = sessions[player:getName()]
        if not sess then
            player:printToPlayer(string.format(
                '[Tower] You are not in a run. Best floor: %d. Trial 2: %s.',
                player:getCharVar('Tower_Best_Floor') or 0,
                (player:getCharVar('PW_Trial2_Done') or 0) == 1 and 'COMPLETE' or 'pending'),
                xi.msg.channel.SYSTEM_3)
        else
            player:printToPlayer(string.format(
                '[Tower] You are on floor %d. Mobs alive: %d.',
                sess.floor or 0, sess.mobsAlive and (function()
                    local n = 0; for _ in pairs(sess.mobsAlive) do n = n + 1 end; return n
                end)() or 0),
                xi.msg.channel.SYSTEM_3)
        end
        return
    end

    -- GM-level commands (permission 4).
    if player:getGMLevel() < 4 then
        player:printToPlayer('[Tower] Permission denied.', xi.msg.channel.SYSTEM_3)
        return
    end

    if sub == 'status' then
        local sessions = getSessions()
        if not sessions then
            player:printToPlayer('[Tower] Tower module not loaded.', xi.msg.channel.SYSTEM_3)
            return
        end
        local count = 0
        for name, sess in pairs(sessions) do
            player:printToPlayer(string.format(
                '[Tower] %s: floor %d', name, sess.floor or 0), xi.msg.channel.SYSTEM_3)
            count = count + 1
        end
        if count == 0 then
            player:printToPlayer('[Tower] No active sessions.', xi.msg.channel.SYSTEM_3)
        end

    elseif sub == 'tp' then
        if not arg2 then
            player:printToPlayer('[Tower] Usage: !tower tp <player>', xi.msg.channel.SYSTEM_3)
            return
        end
        local target = GetPlayerByName(arg2)
        if not target then
            player:printToPlayer('[Tower] Player not found: ' .. arg2, xi.msg.channel.SYSTEM_3)
            return
        end
        local sessions = getSessions()
        if sessions and sessions[arg2] then
            endTowerFor(target, 'abort')
        else
            target:setPos(-15, 0, -18, 128, 210)
        end
        player:printToPlayer('[Tower] Warped ' .. arg2 .. ' out.', xi.msg.channel.SYSTEM_3)

    elseif sub == 'floor' then
        local n = tonumber(arg2)
        if not n or n < 1 or n > 50 then
            player:printToPlayer('[Tower] Usage: !tower floor <1-50>', xi.msg.channel.SYSTEM_3)
            return
        end
        local sessions = getSessions()
        if not sessions then
            player:printToPlayer('[Tower] Tower module not loaded.', xi.msg.channel.SYSTEM_3)
            return
        end
        local sess = sessions[player:getName()]
        if not sess then
            player:printToPlayer('[Tower] You are not in a Tower run.', xi.msg.channel.SYSTEM_3)
            return
        end
        -- Kill live mobs, set floor to N-1 (startFloor will increment).
        for _, mob in pairs(sess.mobsAlive or {}) do
            pcall(function() mob:setHP(0) end)
        end
        sess.mobsAlive = {}
        sess.floor = n - 1
        if xi._et_startFloor then
            xi._et_startFloor(player)
        end
        player:printToPlayer('[Tower] Jumped to floor ' .. n, xi.msg.channel.SYSTEM_3)

    else
        player:printToPlayer('[Tower] Sub-commands: abort | status | tp <name> | floor <N>', xi.msg.channel.SYSTEM_3)
    end
end

return commandObj
