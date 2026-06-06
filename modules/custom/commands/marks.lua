-----------------------------------
-- func: marks
-- desc: Quick Hunt Marks balance - current spendable balance plus an
--       at-a-glance kill-streak summary.
--
-- Usage: !marks
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
    local current  = player:getCharVar('HL_Points')          or 0
    local streak   = player:getCharVar('HL_Streak_Count')    or 0
    local lastKill = player:getCharVar('HL_Streak_LastKill') or 0
    local tier     = player:getCharVar('HL_Tier')            or 1
    if tier < 1 then tier = 1 end

    local now     = os.time()
    local elapsed = now - lastKill
    local active  = (streak > 0) and (elapsed <= 300)

    -- Streak summary
    local streakStr
    if active and streak >= 3 then
        local bonusPct = (streak >= 10 and 50) or (streak >= 5 and 20) or 10
        streakStr = string.format('x%d kills  (+%d%% bonus)  [%ds left]',
            streak, bonusPct, 300 - elapsed)
    elseif active then
        streakStr = string.format('%d / 3 - keep going!  [%ds left]', streak, 300 - elapsed)
    else
        streakStr = 'None  (!streak for details)'
    end

    player:printToPlayer('[Hunt Marks] == Balance ==============================', H)
    player:printToPlayer(string.format('  Current balance:  %d marks', current),  B)
    player:printToPlayer(string.format('  Hunter rank:      Tier %d', tier),      B)
    player:printToPlayer(string.format('  Kill streak:      %s', streakStr),      B)
    player:printToPlayer('  Spend marks at the Hunt Seals NPC in Reisenjima Henge!', B)
end

return commandObj
