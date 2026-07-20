-----------------------------------
-- !apex abort              -- cancel your own active run (points kept)
-- !apex abort <name>       -- GM (perm 1): cancel another player's run
-- !apex status             -- GM (perm 1): list all active sessions
-----------------------------------
local cmdObj = {}

cmdObj.cmdprops = { permission = 0, parameters = 's' }

cmdObj.onTrigger = function(player, args)
    local SYS      = xi.msg.channel.SYSTEM_3
    local sub, name = (args or ''):match('^%s*(%w+)%s*(.-)%s*$')
    sub = (sub or ''):lower()

    local sessions = xi._apex_sessions
    local endRun   = xi._apex_endRun

    if sub == 'enter' then
        player:printToPlayer('[apex] Begin climbs through the Apex Arbiter NPC in Purgonorgo Isle.', SYS)

    elseif sub == 'abort' then
        local target
        if name and name ~= '' then
            if player:getGMLevel() < 1 then
                player:printToPlayer('[apex] GM permission required to abort another player\'s run.', SYS)
                return
            end
            target = GetPlayerByName(name)
            if not target then
                player:printToPlayer(string.format('[apex] Player %q not online.', name), SYS)
                return
            end
        else
            target = player
        end

        if not endRun then
            player:printToPlayer('[apex] ApexTrials module not loaded.', SYS)
            return
        end
        if not (sessions and sessions[target:getName()]) then
            player:printToPlayer(string.format('[apex] %s has no active climb.', target:getName()), SYS)
            return
        end
        endRun(target, 'abort')
        if target:getName() ~= player:getName() then
            player:printToPlayer(string.format('[apex] Run aborted for %s.', target:getName()), SYS)
        end

    elseif sub == 'status' then
        if player:getGMLevel() < 1 then
            player:printToPlayer('[apex] GM permission required.', SYS)
            return
        end
        if not sessions then
            player:printToPlayer('[apex] ApexTrials module not loaded.', SYS)
            return
        end
        local count = 0
        for nm, sess in pairs(sessions) do
            count = count + 1
            player:printToPlayer(string.format('[apex] %s: tier=%d', nm, sess.tier or 0), SYS)
        end
        if count == 0 then
            player:printToPlayer('[apex] No active Apex climbs.', SYS)
        end

    else
        player:printToPlayer('[apex] Usage: !apex abort  |  !apex abort <name> (GM)  |  !apex status (GM)', SYS)
    end
end

return cmdObj
