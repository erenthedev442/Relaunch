-----------------------------------
-- xi.effect.IMPETUS
-----------------------------------
---@type TEffect
local effectObject = {}

effectObject.onEffectGain = function(target, effect)
    target:addListener('MELEE_SWING_HIT', 'IMPETUS_HIT', function(actorArg, targetArg, attack)
        local effectArg = actorArg:getStatusEffect(xi.effect.IMPETUS)
        if not effectArg then
            return
        end

        -- MNK "Impetus Effect" job point gift: raises the maximum attack bonus by
        -- +2 per level. Each stack is +2 ATT, so +1 stack of headroom per JP level.
        local mainPower = effectArg:getPower() + 1 -- Tracks stacks.
        if mainPower > 50 + actorArg:getJobPointLevel(xi.jp.IMPETUS_EFFECT) then
            return
        end

        -- Handle Attack & Critical Hit Rate bonuses
        effectArg:setPower(mainPower)
        effectArg:addMod(xi.mod.ATT, 2)
        effectArg:addMod(xi.mod.CRITHITRATE, 1)

        -- Handle Critical Hit Damage & Accuracy bonuses
        local subPower = effectArg:getSubPower() -- Subpower tracks if user had effect augment, and what quality, when effect was applied.
        if subPower ~= 0 then
            effectArg:addMod(xi.mod.ACC, 2)
            effectArg:addMod(xi.mod.CRIT_DMG_INCREASE, math.floor(subPower / 2))
        end
    end)

    target:addListener('MELEE_SWING_MISS', 'IMPETUS_MISS', function(actorArg, targetArg, attack)
        local effectArg = actorArg:getStatusEffect(xi.effect.IMPETUS)
        if not effectArg then
            return
        end

        local power = effectArg:getPower()
        effectArg:setPower(0)
        -- NOTE (Legendary core patch): this LSB fork's CLuaStatusEffect binds
        -- addMod but NOT delMod, so the stock delMod() calls errored on every
        -- miss ("attempt to call method 'delMod' (a nil value)"). addMod with a
        -- negated amount is the exact inverse -- it nets the accumulated stacks
        -- back out live -- so it restores the intended reset with no C++ rebuild.
        effectArg:addMod(xi.mod.ATT, -2 * power)
        effectArg:addMod(xi.mod.CRITHITRATE, -power)

        local subPower = effectArg:getSubPower() -- Subpower tracks if user had effect augment, and what quality, when effect was applied.
        if subPower ~= 0 then
            effectArg:addMod(xi.mod.ACC, -2 * power)
            effectArg:addMod(xi.mod.CRIT_DMG_INCREASE, -math.floor(subPower / 2) * power)
        end
    end)
end

effectObject.onEffectTick = function(target, effect)
end

effectObject.onEffectLose = function(target, effect)
    target:removeListener('IMPETUS_MISS')
    target:removeListener('IMPETUS_HIT')
end

return effectObject
