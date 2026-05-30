-----------------------------------
-- login_streak.lua
-- Tracks consecutive daily logins and rewards milestone streaks with
-- bonus Hunt Marks.  Streak resets if the player skips a UTC day.
--
-- CharVars:
--   Streak_LastDay      — Julian day (YYYY+DOY UTC) of last login
--   Streak_Count        — current consecutive-day count
--   Streak_Reward_N     — 1 once the N-day milestone reward has been given
--
-- Rewards (one-time per threshold):
--   7 days  → +50 marks
--   14 days → +100 marks
--   30 days → +200 marks
--
-- Note: year-boundary edge case (Dec 31 → Jan 1) may reset the streak
-- for that one transition; acceptable on a small server.
-----------------------------------
require('modules/module_utils')

local m = Module:new('login_streak')

local CV_POINTS = 'HL_Points'

-- { days, bonus_marks, display_label }
local STREAK_MILESTONES = {
    {  7,  50,  '7-Day Streak'  },
    { 14, 100,  '14-Day Streak' },
    { 30, 200,  '30-Day Streak' },
}

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    super(player, firstLogin, zoning)

    if not zoning then
        local today   = tonumber(os.date('!%Y%j')) or 0
        local lastDay = player:getCharVar('Streak_LastDay') or 0
        local streak  = player:getCharVar('Streak_Count')   or 0

        if lastDay == today then
            -- Already processed this login today (re-log / zone-in cascade) — no-op.
            return
        elseif lastDay == today - 1 then
            -- Consecutive day.
            streak = streak + 1
        else
            -- Missed one or more days — reset streak.
            streak = 1
        end

        player:setCharVar('Streak_LastDay', today)
        player:setCharVar('Streak_Count',   streak)

        -- Check streak milestone rewards (one-time per threshold).
        for _, entry in ipairs(STREAK_MILESTONES) do
            local days, bonus, label = entry[1], entry[2], entry[3]
            if streak == days then
                local rewardVar = string.format('Streak_Reward_%d', days)
                if (player:getCharVar(rewardVar) or 0) == 0 then
                    player:setCharVar(rewardVar, 1)
                    local current = player:getCharVar(CV_POINTS) or 0
                    player:setCharVar(CV_POINTS, current + bonus)
                    player:timer(4000, function(p)
                        p:printToPlayer(
                            string.format('[Login Streak] %s — %d days in a row! +%d bonus marks!',
                                label, days, bonus),
                            xi.msg.channel.SYSTEM_3)
                    end)
                end
            end
        end

        -- Progress nudge for streaks shorter than the next milestone.
        if streak > 1 and streak < 7 then
            player:timer(4200, function(p)
                p:printToPlayer(
                    string.format('[Login Streak] %d days in a row — 7 days earns +50 marks!', streak),
                    xi.msg.channel.LINKSHELL)
            end)
        elseif streak > 7 and streak < 14 then
            player:timer(4200, function(p)
                p:printToPlayer(
                    string.format('[Login Streak] %d days in a row — 14 days earns +100 marks!', streak),
                    xi.msg.channel.LINKSHELL)
            end)
        elseif streak > 14 and streak < 30 then
            player:timer(4200, function(p)
                p:printToPlayer(
                    string.format('[Login Streak] %d days in a row — 30 days earns +200 marks!', streak),
                    xi.msg.channel.LINKSHELL)
            end)
        end
    end
end)

return m
