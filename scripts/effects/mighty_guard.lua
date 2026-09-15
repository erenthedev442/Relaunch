-----------------------------------
-- xi.effect.MIGHTY_GUARD
-- Player BLU Unbridled package lives on this effect so it cannot
-- silently stack Cocoon (75% DEF) and Erratic Flutter (5 min Haste)
-- with a second Defense Boost / Haste / Regen 30 kit.
-- Mob casts use power 1 and get the icon only; they already apply
-- Protect / Shell / Haste themselves.
-----------------------------------
---@type TEffect
local effectObject = {}

local PLAYER_REGEN_FLOOR = 8

effectObject.onEffectGain = function(target, effect)
    local regen = effect:getPower()
    if regen < PLAYER_REGEN_FLOOR then
        return
    end

    effect:addMod(xi.mod.REGEN, regen)
    effect:addMod(xi.mod.MDEF, effect:getSubPower())
    effect:addMod(xi.mod.HASTE_MAGIC, effect:getTier())
    -- -5% DT. Felt in the Unbridled window, not a second Cocoon.
    effect:addMod(xi.mod.DMG, -500)
end

effectObject.onEffectTick = function(target, effect)
end

effectObject.onEffectLose = function(target, effect)
end

return effectObject
