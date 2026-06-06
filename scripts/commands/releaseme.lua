 -----------------------------------
-- func: releaseme [target] [mode]
-- desc: Force-clears stuck event / NPC-sequence state on a player.
--
--       Why this exists: the vanilla !release ends the *current* event
--       but does NOT drain the event queue and does NOT force the
--       client to refresh its entity cache. When a custom dynamic NPC
--       despawns mid-interaction, the client keeps polling its dead
--       entity ID and stays wedged. The FFXI client also locks chat
--       input during a cutscene, so a stuck player often CAN'T even
--       type !releaseme on themselves.
--
--       Usage (target is optional — defaults to self):
--         !releaseme                  -- gentle: release + position resync
--         !releaseme force            -- nuclear: homepoint warp
--         !releaseme kick             -- last resort: force-logout
--         !releaseme Jbae             -- gentle rescue of another player
--         !releaseme Jbae force       -- nuclear rescue of another player
--         !releaseme Jbae kick        -- kick another player so they relog
--
--       If YOU are the one stuck and can't open chat, log in an alt
--       (or have a friend) and run `!releaseme YourCharName force` to
--       rescue from the outside.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 'ss',
}

-- Recognised mode flags. First-position arg is treated as a mode flag if
-- it's one of these; otherwise it's interpreted as a target player name.
local MODE_FLAGS =
{
    ['force'] = 'force',  ['-f']   = 'force',  ['warp'] = 'force',  ['home'] = 'force',  ['hp'] = 'force',
    ['kick']  = 'kick',   ['quit'] = 'kick',   ['logout'] = 'kick', ['boot'] = 'kick',
    ['gentle'] = 'gentle', [''] = 'gentle',
}

local function parseArgs(player, arg1, arg2)
    -- Cases:
    --   (nil,    nil)             -> self, gentle
    --   ("force", nil)            -> self, force            (mode-only)
    --   ("Jbae", nil)             -> Jbae, gentle           (target-only)
    --   ("Jbae", "force")         -> Jbae, force            (target + mode)
    --   ("force", "Jbae")         -> Jbae, force            (mode + target, friendly typo)
    if arg1 == nil then
        return player, 'gentle'
    end

    -- Mode-only?
    if MODE_FLAGS[arg1] then
        local mode = MODE_FLAGS[arg1]
        if arg2 == nil then
            return player, mode
        end
        -- arg1 is mode, arg2 is target name
        local t = GetPlayerByName(arg2)
        if not t then
            player:printToPlayer(string.format('Player named "%s" not found.', arg2))
            return nil
        end
        return t, mode
    end

    -- arg1 is target name
    local t = GetPlayerByName(arg1)
    if not t then
        player:printToPlayer(string.format('Player named "%s" not found.', arg1))
        return nil
    end
    local mode = MODE_FLAGS[arg2 or ''] or 'gentle'
    return t, mode
end

commandObj.onTrigger = function(player, arg1, arg2)
    local target, mode = parseArgs(player, arg1, arg2)
    if not target then
        return
    end

    if mode == 'kick' then
        -- Last-resort force-logout. Client disconnects; on next login the
        -- character lands at their save point with zero stuck state. Use
        -- when warp won't even fire (rare but possible if zone-change
        -- processing itself is wedged).
        target:forceLogout()
        if target:getID() ~= player:getID() then
            player:printToPlayer(string.format('[releaseme] Force-logged %s. They can log back in clean.', target:getName()))
        end
        return
    end

    if mode == 'force' then
        -- Warp to homepoint. Zone change unconditionally tears down all
        -- per-zone state (event, eventQueue, inSequence, locked) and the
        -- client rebuilds its entity cache from scratch on zone-in.
        target:warp()
        if target:getID() == player:getID() then
            target:printToPlayer('[releaseme] Forced you to your homepoint. Stuck state cleared.')
        else
            target:printToPlayer('[releaseme] You were warped home to clear stuck state.')
            player:printToPlayer(string.format('[releaseme] Warped %s home.', target:getName()))
        end
        return
    end

    -- Gentle: release() sends EVENTUCOFF, ends current event, clears
    -- inSequence. Then a zero-delta setPos forces a position-update
    -- packet, which makes the client re-sync world view and stop
    -- polling dead entity IDs.
    target:release()

    local x = target:getXPos()
    local y = target:getYPos()
    local z = target:getZPos()
    local r = target:getRotPos()
    target:setPos(x, y, z, r)

    if target:getID() == player:getID() then
        target:printToPlayer('[releaseme] Released. If still stuck, try: !releaseme force (or !releaseme kick).')
    else
        target:printToPlayer('[releaseme] Someone released you from a stuck state.')
        player:printToPlayer(string.format('[releaseme] Released %s.', target:getName()))
    end
end

return commandObj
