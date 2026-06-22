-----------------------------------
-- barrage_tuning.lua
--
-- Extends the RNG Barrage effect duration from the retail 1:00 to 5:00.
--
-- Merge-safe override of xi.job_utils.ranger.useBarrage (barrage.lua calls it by
-- full path at runtime, so this intercepts). Pairs with the recast bump to 6:00 in
-- modules/custom/sql/zz_barrage_recast.sql.
--
-- DURATION SEMANTICS: paired with the C++ change that removed the per-shot consume
-- (src/map/entities/battleentity.cpp -- "Barrage is intentionally NO LONGER consumed
-- per shot"), Barrage now PERSISTS for this full 5:00 and EVERY ranged attack
-- barrages -- a timed RNG DD buff (5:00 uptime vs the 6:00 recast). A throwing
-- weapon still drops it (range_state.cpp, retail-accurate). The C++ consume removal
-- needs a [REBUILD]; this duration override needs a map restart -- they ship
-- together.
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
