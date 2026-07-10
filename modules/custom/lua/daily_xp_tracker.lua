-----------------------------------
-- daily_xp_tracker.lua
--
-- Feeds the Daily Board's "XP grind" objective (2026-07-10, report: Burtgang --
-- "gain XP should be the only rotating task"). The Daily Board is snapshot-based:
-- progress = current lifetime CharVar - day-start baseline, so it needs a
-- MONOTONIC lifetime counter to diff against. The engine exposes none for XP:
--   * mob-kill EXP is awarded in C++ (charutils::DistributeExperiencePoints); there
--     is no Lua exp-gain event to hook.
--   * player:getExp() is exp WITHIN the current level and resets on level-up, so it
--     can't be diffed as a running total.
-- So we bank our own counter here: every credited mob kill adds a mob-level-weighted
-- amount to XP_Grind_Lifetime. This is "combat XP grind" progress (kill things ->
-- gain XP), weighted so higher content counts for more -- the same mob-level proxy
-- the Fellow XP faucet already uses. Not the player's literal EXP number, but a
-- faithful, monotonic measure of "how much did you grind today".
--
-- xi.mob.onMobDeathEx is fanned out by the core once per alliance member (with the
-- `player` arg = that member), which mirrors how EXP itself is distributed -- so
-- every party member who would earn EXP from the kill gets grind credit here too.
--
-- Restart-gated: addOverride hook, registers at map boot.
-----------------------------------
require('modules/module_utils')

local m = Module:new('daily_xp_tracker')

local CV = 'XP_Grind_Lifetime'   -- monotonic; the Daily Board diffs this (baselines.xp)

-- Per-credited-kill grind points = clamp(mobLevel, MIN, MAX). At endgame (~Lv100-140
-- mobs) that's ~100-140/kill; while leveling, less. MAX caps a stray super-mob so a
-- single kill can't trivialize a daily objective.
local PER_MIN = 5
local PER_MAX = 300

m:addOverride('xi.mob.onMobDeathEx', function(mob, player, isKiller, isWeaponSkillKill)
    super(mob, player, isKiller, isWeaponSkillKill)
    pcall(function()
        if player == nil or player:getObjType() ~= xi.objType.PC then return end
        local lvl  = mob:getMainLvl() or 1
        local gain = math.max(PER_MIN, math.min(PER_MAX, lvl))
        player:setCharVar(CV, (player:getCharVar(CV) or 0) + gain)
    end)
end)

return m
