-----------------------------------
-- daily_login_bonus.lua
-- Grants 50 Hunt Marks (DAILY_BONUS) the first time a player logs in each UTC day.
-- Creates a daily touchpoint reason to log in even on low-activity days.
--
-- CharVars:
--   Daily_Login_Day  - Julian day (YYYY + day-of-year) of last bonus
-----------------------------------
require('modules/module_utils')

local m = Module:new('daily_login_bonus')

local DAILY_BONUS = 50
local CV_POINTS   = 'HL_Points'

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    -- Real-login gate (see announce_player_login.lua): capture gameLogin before super() clears it.
    -- `not zoning` misfires on zone-ins that arrive with char_stats.zoning == 0; gameLogin == 1 is
    -- set by the core only for an actual login. The Daily_Login_Day guard below already masked the
    -- double-fire, but this stops the wasted per-zone reprocessing.
    local isLogin = player:getLocalVar('gameLogin') == 1

    super(player, firstLogin, zoning)

    if isLogin then
        local today   = tonumber(os.date('!%Y%j')) or 0  -- UTC Julian day
        local lastDay = player:getCharVar('Daily_Login_Day') or 0

        if lastDay ~= today then
            player:setCharVar('Daily_Login_Day', today)
            local current = player:getCharVar(CV_POINTS) or 0
            player:setCharVar(CV_POINTS, current + DAILY_BONUS)

            -- Delayed so the message lands after the login broadcast + MOTD.
            player:timer(3500, function(p)
                p:printToPlayer(
                    string.format('[Daily Bonus] +%d Hunt Marks for logging in today! Come back tomorrow for more.',
                        DAILY_BONUS),
                    xi.msg.channel.SYSTEM_3)
            end)
        end
    end
end)

return m
