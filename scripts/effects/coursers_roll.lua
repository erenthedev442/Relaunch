-----------------------------------
-- xi.effect.COURSERS_ROLL
-- FJB: enabled -- grants Snapshot. Power is already defined for COURSERS_ROLL
-- in job_utils/corsair.lua, so the addMod/delMod just needed uncommenting.
-----------------------------------
---@type TEffect
local effectObject = {}

effectObject.onEffectGain = function(target, effect)
    target:addMod(xi.mod.SNAPSHOT, effect:getPower())
end

effectObject.onEffectTick = function(target, effect)
end

effectObject.onEffectLose = function(target, effect)
    target:delMod(xi.mod.SNAPSHOT, effect:getPower())
    xi.job_utils.corsair.onRollEffectLose(target, effect)
end

return effectObject
