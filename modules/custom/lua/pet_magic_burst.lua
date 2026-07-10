-----------------------------------
-- pet_magic_burst.lua
--
-- Let player pets MAGIC BURST with their magical TP moves (player report,
-- Herdofturtles 2026-07-10: jug-pet Fireball from Warlike Patrick and the
-- Fellow's magical signature moves never burst on an open skillchain window).
--
-- ROOT CAUSE: xi.mobskills.mobMagicalMove only applies the burst multiplier
-- when the individual skill script passes params.canMagicBurst = true, and
-- only 6 of the ~368 magical mob-skill scripts do (aero_iv/blizzard_iv/
-- fire_iv/stone_iv/water_iv/thunderstrike). Jug-pet moves (fireball.lua, ...)
-- and every Fellow signature move (Charged Whisker, Cursed Sphere, Bomb Toss,
-- ...) omit it, so the flag defaults to false and formMagicBurst is never even
-- consulted. On retail, pet magical abilities DO magic burst.
--
-- THE FIX: one override of the shared magical mob-skill entry point. When the
-- skill's user has a PC master (jug/charmed BST pets, the Fellow, trusts --
-- the same master:isPC() gate mobMagicalMove itself already uses for
-- BP_DAMAGE) and the skill script didn't take an explicit stance, default
-- canMagicBurst to TRUE. The burst window/element matching stays entirely in
-- xi.magicburst.formMagicBurst, so this only opens the door -- a move still
-- only bursts on a live skillchain window whose resonance matches its element.
--
-- SCOPE: masterless mobs are untouched (an explicit nil-master check, so mob
-- TP moves keep the upstream per-skill opt-in), and skill scripts that DO set
-- canMagicBurst (true or false) keep their word. Breath moves (mobBreathMove)
-- are deliberately not covered: retail breath damage does not burst; DRG
-- wyvern breaths burst through their own job_utils/dragoon.lua path already.
--
-- Pure-Lua override module -> needs ONE map restart to load (no rebuild).
-----------------------------------
require('modules/module_utils')
require('scripts/globals/mobskills')

local m = Module:new('pet_magic_burst')

m:addOverride('xi.mobskills.mobMagicalMove', function(mob, target, skill, action, skillParams)
    if skillParams.canMagicBurst == nil then
        local master = mob:getMaster()
        if master and master:isPC() then
            skillParams.canMagicBurst = true
        end
    end

    return super(mob, target, skill, action, skillParams)
end)

return m
