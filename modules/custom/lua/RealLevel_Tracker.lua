-----------------------------------
-- RealLevel_Tracker.lua
-- Keeps every character's RealLevel CharVar fresh on login, so the website
-- "Highest Real Level" leaderboard (docs/community/leaderboards.md) populates
-- automatically -- nobody has to run !reallevel. Uses the exact same formula
-- as the command (shared lib modules/custom/lua/real_level.lua).
--
-- This is an onGameIn OVERRIDE module, so it needs a MAP RESTART to activate
-- (override hooks do not hot-reload). Gated on the real-login signal
-- (gameLogin == 1, the same discriminator announce_player_login uses), so it
-- fires once per login, never on a zone change. The compute is deferred a few
-- seconds so the character's gear / Job Points / merits are fully loaded --
-- getAverageItemLevel() reads 0 at the bare hook moment.
-----------------------------------
require('modules/module_utils')
local realLib = require('modules/custom/lua/real_level')
-----------------------------------
local m = Module:new('reallevel_tracker')

m:addOverride('xi.player.onGameIn', function(player, firstLogin, zoning)
    -- Capture the login signal BEFORE super() runs (onGameIn clears gameLogin
    -- to 0 on exit). gameLogin == 1 ONLY on a real login from character select.
    local isLogin = player:getLocalVar('gameLogin') == 1

    super(player, firstLogin, zoning)

    if isLogin then
        -- Defer ~3s: gear / stats aren't populated at the bare hook moment, so
        -- getAverageItemLevel() / getSpentJobPoints() would read low. Mirrors
        -- announce_player_login's deferred-timer pattern (timers fire fine at
        -- login -- the drop only affects mid-session zone transitions).
        player:timer(3000, function(p)
            realLib.refresh(p)
        end)
    end
end)

return m
