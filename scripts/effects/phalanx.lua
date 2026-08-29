-----------------------------------
-- xi.effect.PHALANX
-----------------------------------
---@type TEffect
local effectObject = {}

-- Keep retail-style "Phalanx received" gear useful without letting custom
-- augment stacking erase encounter damage.  This is a total character cap,
-- not a per-item or per-augment allowance.
local PHALANX_RECEIVED_CAP = 15

effectObject.onEffectGain = function(target, effect)
    -- Barrier Tusk marks its percentage reduction as -1500 subpower.  Keeping
    -- this separate prevents ordinary Phalanx and Phalanx-received gear from
    -- being interpreted as percentage damage taken.
    if effect:getSubPower() == -1500 then
        effect:addMod(xi.mod.DMG, -1500)
        return
    end

    local received = utils.clamp(target:getMod(xi.mod.PHALANX_RECEIVED), 0, PHALANX_RECEIVED_CAP)
    effect:addMod(xi.mod.PHALANX, effect:getPower() + received)
end

effectObject.onEffectTick = function(target, effect)
end

effectObject.onEffectLose = function(target, effect)
end

return effectObject
