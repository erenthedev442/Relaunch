-----------------------------------
-- xi.effect.CLIMACTIC_FLOURISH
--
-- Power = remaining guaranteed crits (one per finishing move spent).
-- While up: CRITHITRATE +100 and CRIT_DMG_INCREASE +50. Each landed auto
-- or weaponskill hit spends one charge; the effect falls off at 0.
-----------------------------------
---@type TEffect
local effectObject = {}

effectObject.onEffectGain = function(target, effect)
    target:addMod(xi.mod.CRITHITRATE,       100)
    target:addMod(xi.mod.CRIT_DMG_INCREASE,  50)
end

effectObject.onEffectTick = function(target, effect)
end

effectObject.onEffectLose = function(target, effect)
    target:delMod(xi.mod.CRITHITRATE,       100)
    target:delMod(xi.mod.CRIT_DMG_INCREASE,  50)
end

return effectObject
