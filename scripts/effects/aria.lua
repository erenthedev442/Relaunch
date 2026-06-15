-----------------------------------
-- xi.effect.ARIA
-- Aria of Passion: Physical Damage Limit+ song.
-- effect:getPower() = DAMAGE_LIMITP percentage (e.g. 20 = +20%)
-----------------------------------
---@type TEffect
local effectObject = {}

effectObject.onEffectGain = function(target, effect)
    target:addMod(xi.mod.DAMAGE_LIMITP, effect:getPower())
end

effectObject.onEffectTick = function(target, effect)
end

effectObject.onEffectLose = function(target, effect)
    target:delMod(xi.mod.DAMAGE_LIMITP, effect:getPower())
end

return effectObject
