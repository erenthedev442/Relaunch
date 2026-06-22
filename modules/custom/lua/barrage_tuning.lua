-----------------------------------
-- barrage_tuning.lua
--
-- Extends the RNG Barrage effect duration from the retail 1:00 to 5:00.
--
-- Merge-safe override of xi.job_utils.ranger.useBarrage (barrage.lua calls it by
-- full path at runtime, so this intercepts). Pairs with the recast bump to 6:00 in
-- modules/custom/sql/zz_barrage_recast.sql.
--
-- IMPORTANT -- what "duration" means here: Barrage is CONSUMED on the next ranged
-- attack (src/map/entities/battleentity.cpp checks EFFECT_BARRAGE, fires the extra
-- shots, then DelStatusEffectSilent removes it). So this 5:00 is the WINDOW you
-- have to fire that one barraged shot before the effect lapses unused -- it is NOT
-- 5 minutes of every-shot barraging. Turning Barrage into a persistent "barrage
-- every shot for 5 min" buff would additionally require dropping that per-shot
-- consume in battleentity.cpp (a C++ change + rebuild).
--
-- Override module -> needs a map RESTART to load.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/job_utils/ranger')

local m = Module:new('barrage_tuning')

local DURATION = 300 -- seconds (5:00)

m:addOverride('xi.job_utils.ranger.useBarrage', function(player, target, ability, action)
    player:addStatusEffect(xi.effect.BARRAGE, { duration = DURATION, origin = player })

    return xi.effect.BARRAGE
end)

return m
