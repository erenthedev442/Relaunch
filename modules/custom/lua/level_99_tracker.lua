-----------------------------------
-- level_99_tracker.lua
-- Stamps the Unix timestamp on the player CharVar `First99_At` the first
-- time any job reaches level 99. Powers the "Fastest 1 -> 99" leaderboard
-- on the docs site.
--
-- Pure Lua, no source edits. Hooks the upstream xi.player.onPlayerLevelUp.
-- Lock-once: re-leveling another job to 99 doesn't overwrite the stamp.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/player')

local m = Module:new('level_99_tracker')

m:addOverride('xi.player.onPlayerLevelUp', function(player)
    super(player)

    -- Already stamped - nothing to do. Cheap path so we don't open up
    -- the level-check loop for veterans.
    if (player:getCharVar('First99_At') or 0) ~= 0 then
        return
    end

    -- player:getMainLvl() is the main job's actual level. We only care about
    -- main-job level-ups here because LSB's onPlayerLevelUp fires for main.
    -- The Subjob EXP Share module's own sub level-ups don't trip this - they
    -- use setsLevel() directly without firing the listener - so this stamp
    -- specifically records "first time your MAIN job hit 99," which is what
    -- players intuitively expect.
    if player:getMainLvl() >= 99 then
        player:setCharVar('First99_At', os.time())
    end
end)

return m
