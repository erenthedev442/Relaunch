-----------------------------------
-- xi.effect.ACCURACY_BOOST
--
-- getPower     = ACC
-- getSubPower  = RACC
--
-- Aura-applied (ALWAYS_EXPIRING): Acc and RAcc both use getPower() because
-- the aura applicator only forwards COLURE subPower as the child effect's
-- power (no nested subPower). Used by Trust Kuyin Hathdenna so Acc/RAcc
-- stack with player Indi-Precision (GEO_ACCURACY_BOOST).
-----------------------------------
---@type TEffect
local effectObject = {}

effectObject.onEffectGain = function(target, effect)
    local power = effect:getPower()
    target:addMod(xi.mod.ACC, power)

    if effect:hasEffectFlag(xi.effectFlag.ALWAYS_EXPIRING) then
        target:addMod(xi.mod.RACC, power)
    elseif effect:getSubPower() > 0 then
        target:addMod(xi.mod.RACC, effect:getSubPower())
    end
end

effectObject.onEffectTick = function(target, effect)
    -- Aura-applied Acc (e.g. Kuyin) is continually refreshed — do not decay.
    if effect:hasEffectFlag(xi.effectFlag.ALWAYS_EXPIRING) then
        return
    end

    -- the effect loses accuracy of 1 every 3 ticks depending on the source of the acc boost
    local boostACCEffectSize = effect:getPower()
    if boostACCEffectSize > 0 then
        effect:setPower(boostACCEffectSize - 1)
        target:delMod(xi.mod.ACC, 1)
    end
end

effectObject.onEffectLose = function(target, effect)
    local boostACCEffectSize = effect:getPower()
    if boostACCEffectSize > 0 then
        target:delMod(xi.mod.ACC, boostACCEffectSize)
        if effect:hasEffectFlag(xi.effectFlag.ALWAYS_EXPIRING) then
            target:delMod(xi.mod.RACC, boostACCEffectSize)
        end
    end

    if not effect:hasEffectFlag(xi.effectFlag.ALWAYS_EXPIRING) and effect:getSubPower() > 0 then
        target:delMod(xi.mod.RACC, effect:getSubPower())
    end
end

return effectObject
