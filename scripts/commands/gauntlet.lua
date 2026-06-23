-----------------------------------
-- !gauntlet abort        -- any player: cancel your own active run
-- !gauntlet abort <name> -- GM (perm 1): cancel another player's run
-- !gauntlet status       -- GM (perm 1): list all active sessions
-----------------------------------
local cmdObj = {}

cmdObj.cmdprops = { permission = 0, parameters = 's' }

cmdObj.onTrigger = function(player, args)
    local SYS  = xi.msg.channel.SYSTEM_3
    local sub, name = (args or ''):match('^%s*(%w+)%s*(.-)%s*$')
    sub = (sub or ''):lower()

    local endRun  = xi._gauntlet_endRun
    local sessions = xi._gauntlet_sessions

    if sub == 'abort' then
        local target
        if name and name ~= '' then
            if player:getGMLevel() < 1 then
                player:printToPlayer('[gauntlet] GM permission required to abort another player\'s run.', SYS)
                return
            end
            target = GetPlayerByName(name)
            if not target then
                player:printToPlayer(string.format('[gauntlet] Player %q not online.', name), SYS)
                return
            end
        else
            target = player
        end

        if not endRun then
            player:printToPlayer('[gauntlet] TheGauntlet module not loaded.', SYS)
            return
        end
        if not (sessions and sessions[target:getName()]) then
            player:printToPlayer(string.format('[gauntlet] %s has no active Gauntlet run.', target:getName()), SYS)
            return
        end
        endRun(target, 'abort')
        if target:getName() ~= player:getName() then
            player:printToPlayer(string.format('[gauntlet] Run aborted for %s.', target:getName()), SYS)
        end

    elseif sub == 'status' then
        if player:getGMLevel() < 1 then
            player:printToPlayer('[gauntlet] GM permission required.', SYS)
            return
        end
        if not sessions then
            player:printToPlayer('[gauntlet] TheGauntlet module not loaded.', SYS)
            return
        end
        local count = 0
        for nm, sess in pairs(sessions) do
            count = count + 1
            player:printToPlayer(string.format(
                '[gauntlet] %s: level=%d phase=%s nm=%s',
                nm, sess.level or 0, sess.phase or '?',
                sess.nm and 'alive' or 'none'), SYS)
        end
        if count == 0 then
            player:printToPlayer('[gauntlet] No active Gauntlet runs.', SYS)
        end

    else
        player:printToPlayer('[gauntlet] Usage: !gauntlet abort  |  !gauntlet abort <name> (GM)  |  !gauntlet status (GM)', SYS)
    end
end

return cmdObj
