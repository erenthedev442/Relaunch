-----------------------------------
-- func: streak
-- desc: Shows the current kill streak count, active bonus tier, and
--       seconds remaining in the 5-minute window before reset.
--
-- Usage: !streak
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

local H = xi.msg.channel.SYSTEM_3
local B = xi.msg.channel.LINKSHELL

commandObj.onTrigger = function(player)
    local streak   = player:getCharVar('HL_Streak_Count')    or 0
    local lastKill = player:getCharVar('HL_Streak_LastKill') or 0
    local now      = os.time()
    local elapsed  = now - lastKill
    local active   = (streak > 0) and (elapsed <= 300)
    local secsLeft = active and (300 - elapsed) or 0

    player:printToPlayer('[Kill Streak] ── Status ──────────────────────────────', H)

    if not active then
        player:printToPlayer('  No active streak.', B)
        player:printToPlayer('  Kill NMs back-to-back within 5 minutes to build one!', B)
        player:printToPlayer('  x3 kills = +10%   x5 kills = +20%   x10+ kills = +50%', B)
        return
    end

    -- Active bonus tier
    local bonusPct = 0
    if     streak >= 10 then bonusPct = 50
    elseif streak >=  5 then bonusPct = 20
    elseif streak >=  3 then bonusPct = 10
    end

    player:printToPlayer(string.format('  Current streak:  x%d kills', streak), B)

    if bonusPct > 0 then
        player:printToPlayer(
            string.format('  Active bonus:    +%d%% base marks each kill', bonusPct), B)
    else
        player:printToPlayer(
            string.format('  Active bonus:    None yet  (need %d total)', 3 - streak + 1), B)
    end

    player:printToPlayer(string.format('  Window:          %d seconds remaining', secsLeft), B)

    -- Next bonus tier
    if     streak < 3  then
        player:printToPlayer(
            string.format('  Next bonus at:   x3 kills (+10%%)  — %d more kill(s)', 3 - streak), B)
    elseif streak < 5  then
        player:printToPlayer(
            string.format('  Next bonus at:   x5 kills (+20%%)  — %d more kill(s)', 5 - streak), B)
    elseif streak < 10 then
        player:printToPlayer(
            string.format('  Next bonus at:   x10 kills (+50%%) — %d more kill(s)', 10 - streak), B)
    else
        player:printToPlayer('  Maximum bonus tier reached!  (+50%% per kill)', B)
    end
end

return commandObj
