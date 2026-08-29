-----------------------------------
-- xi.effect.MAGIC_ATK_BOOST
-----------------------------------
---@type TEffect
local effectObject = {}

effectObject.onEffectGain = function(target, effect)
    if effect:getPower() > 100 then
        effect:setPower(50)
    end

    effect:addMod(xi.mod.MATT, effect:getPower())
    if effect:getSubPower() > 0 then
        effect:addMod(xi.mod.MAGIC_DAMAGE, effect:getSubPower())
    end
end

effectObject.onEffectTick = function(target, effect)
end

effectObject.onEffectLose = function(target, effect)
end

return effectObject
