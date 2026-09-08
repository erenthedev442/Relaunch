-----------------------------------
-- !gauntlet abort        -- any player: cancel your own active run
-- !gauntlet abort <name> -- owner/dev GM5: cancel another player's run
-- !gauntlet status       -- support GM1: list all active sessions
-- !gauntlet fix <name>   -- owner/dev GM5; GM1 uses audited !gmcontent
-- !gauntlet set <name> <level> -- owner/dev GM5: place player at a Gauntlet level
-----------------------------------
local cmdObj = {}

cmdObj.cmdprops = { permission = 0, parameters = 's' }

cmdObj.onTrigger = function(player, args)
    local SYS  = xi.msg.channel.SYSTEM_3
    local sub, name = (args or ''):match('^%s*(%w+)%s*(.-)%s*$')
    sub = (sub or ''):lower()

    local endRun  = xi._gauntlet_endRun
    local sessions = xi._gauntlet_sessions
    local C = require('modules/custom/lua/gauntlet_catalog')

    if sub == 'abort' then
        local target
        if name and name ~= '' then
            if player:getGMLevel() < 5 then
                player:printToPlayer('[gauntlet] Use !gmcontent reset gauntlet <player> <reason>.', SYS)
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
            if sess.lane then
                player:printToPlayer(string.format(
                    '[gauntlet]   lane=%d slot=%d', sess.lane or 0, sess.laneSlot or 0), SYS)
            end
        end
        if count == 0 then
            player:printToPlayer('[gauntlet] No active Gauntlet runs.', SYS)
        end

    elseif sub == 'fix' then
        if player:getGMLevel() < 5 then
            player:printToPlayer('[gauntlet] Use !gmcontent reset gauntlet <player> <reason>.', SYS)
            return
        end
        if not sessions then
            player:printToPlayer('[gauntlet] TheGauntlet module not loaded.', SYS)
            return
        end

        local targetName = name and name ~= '' and name or player:getName()
        local target = GetPlayerByName(targetName)
        if not target then
            player:printToPlayer(string.format('[gauntlet] Player %q not online.', targetName), SYS)
            return
        end

        local sess = sessions[target:getName()]
        if sess and sess.nm then
            pcall(function() sess.nm:setHP(0) end)
            pcall(function() sess.nm:despawn() end)
        end

        sessions[target:getName()] = nil
        target:delStatusEffect(xi.effect.LEVEL_RESTRICTION)
        target:setPos(C.EXIT_POS.x, C.EXIT_POS.y, C.EXIT_POS.z, C.EXIT_POS.rot, C.EXIT_POS.zoneId)
        player:printToPlayer(string.format('[gauntlet] Cleared Gauntlet state for %s.', target:getName()), SYS)

    elseif sub == 'set' then
        if player:getGMLevel() < 5 then
            player:printToPlayer('[gauntlet] GM5 permission required.', SYS)
            return
        end
        if not sessions then
            player:printToPlayer('[gauntlet] TheGauntlet module not loaded.', SYS)
            return
        end

        local targetName, levelText = (name or ''):match('^(%S+)%s+(%d+)$')
        local level = tonumber(levelText or '')
        if not targetName or not level or level < 1 or level > 10 then
            player:printToPlayer('[gauntlet] Usage: !gauntlet set <name> <level 1-10>', SYS)
            return
        end

        local target = GetPlayerByName(targetName)
        if not target then
            player:printToPlayer(string.format('[gauntlet] Player %q not online.', targetName), SYS)
            return
        end

        local old = sessions[target:getName()]
        if old and old.nm then
            pcall(function() old.nm:setHP(0) end)
            pcall(function() old.nm:despawn() end)
        end

        sessions[target:getName()] = {
            level = level,
            phase = 'choose',
            nm = nil,
            clearedLevels = level - 1,
        }
        target:delStatusEffect(xi.effect.LEVEL_RESTRICTION)
        target:setPos(C.WARP_IN.x, C.WARP_IN.y, C.WARP_IN.z, C.WARP_IN.rot, C.ARENA_ZONE)
        player:printToPlayer(string.format('[gauntlet] Set %s to Gauntlet level %d.', target:getName(), level), SYS)

    else
        player:printToPlayer('[gauntlet] Usage: !gauntlet abort | abort <name> | status | fix <name> | set <name> <level>', SYS)
    end
end

return cmdObj
