-----------------------------------
-- xi.effect.GALLANTS_ROLL
-----------------------------------
---@type TEffect
local effectObject = {}

effectObject.onEffectGain = function(target, effect)
    -- FJB: Gallant's Roll grants DEFENSE. It was applying xi.mod.DMG with a
    -- NEGATIVE power (a weapon-damage penalty), so the "defense roll" did
    -- nothing useful. Fixed to +DEF (the roll's intended stat).
    target:addMod(xi.mod.DEF, effect:getPower())
end

effectObject.onEffectTick = function(target, effect)
end

effectObject.onEffectLose = function(target, effect)
    target:delMod(xi.mod.DEF, effect:getPower())
    xi.job_utils.corsair.onRollEffectLose(target, effect)
end

return effectObject
