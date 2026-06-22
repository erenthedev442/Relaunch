-----------------------------------
-- func: gmreset
-- desc: GM tool -- force-reset a stuck Game Master (Wave Mode) session in Escha.
--       Despawns that run's lingering mobs and clears the session so the player
--       (or you) can start a fresh one. Use when a session has frozen and
--       re-talking to the Game Master NPC won't abort it.
--
-- Usage:
--   !gmreset            -- reset YOUR own Game Master session
--   !gmreset Loamy      -- reset Loamy's session (online: despawns + clears;
--                          offline: just clears the leaked entry)
--
-- The session table + end-session hook are exposed by GameMaster.lua
-- (xi._gm_sessions / xi._gm_endSession). NOTE: a full map restart already
-- wipes ALL Game Master sessions (they're in-memory) -- this is the no-restart,
-- per-player version.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,   -- GM
    parameters = 's',
}

local SYS = xi.msg.channel.SYSTEM_3

commandObj.onTrigger = function(player, target)
    local name     = (target and target ~= '') and target or player:getName()
    local sessions = xi._gm_sessions

    if not sessions then
        player:printToPlayer('[GM Reset] Game Master module not loaded (needs a map restart to expose the reset hook).', SYS)
        return
    end

    if not sessions[name] then
        player:printToPlayer(string.format('[GM Reset] No active Game Master session for "%s".', name), SYS)
        return
    end

    local owner = GetPlayerByName(name)
    if owner and xi._gm_endSession then
        -- Online: proper teardown -- despawns this run's mobs + clears + notifies.
        xi._gm_endSession(owner, false)
    else
        -- Offline owner (leaked entry): just clear it so a new run can start.
        sessions[name] = nil
    end

    player:printToPlayer(string.format('[GM Reset] Game Master session reset for "%s".', name), SYS)
end

return commandObj
