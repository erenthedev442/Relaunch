-----------------------------------
-- xi.effect.MARCH
-- getPower returns the TIER (e.g. 1, 2, 3, 4)
-- DO NOT ALTER ANY OF THE EFFECT VALUES! DO NOT ALTER EFFECT POWER!
-- TODO: Find a better way of doing this. Need to account for varying modifiers + CASTER's skill (not target)
-----------------------------------
---@type TEffect
local effectObject = {}

effectObject.onEffectGain = function(target, effect)
    target:addMod(xi.mod.HASTE_MAGIC, effect:getPower())
    target:addMod(xi.mod.DEX, effect:getSubPower()) -- Apply Stat Buff from AUGMENT_SONG_STAT

    if effect:getTier() == 3 then -- Honor March
        local songPower = math.ceil(effect:getPower() * 1024 / 10000)
        local accuracy  = math.floor(songPower / 3)
        local attack    = accuracy * 4

        target:addMod(xi.mod.ACC, accuracy)
        target:addMod(xi.mod.RACC, accuracy)
        target:addMod(xi.mod.ATT, attack)
        target:addMod(xi.mod.RATT, attack)
    end
end

effectObject.onEffectTick = function(target, effect)
end

effectObject.onEffectLose = function(target, effect)
    target:delMod(xi.mod.HASTE_MAGIC, effect:getPower())
    target:delMod(xi.mod.DEX, effect:getSubPower()) -- Remove Stat Buff from AUGMENT_SONG_STAT

    if effect:getTier() == 3 then -- Honor March
        local songPower = math.ceil(effect:getPower() * 1024 / 10000)
        local accuracy  = math.floor(songPower / 3)
        local attack    = accuracy * 4

        target:delMod(xi.mod.ACC, accuracy)
        target:delMod(xi.mod.RACC, accuracy)
        target:delMod(xi.mod.ATT, attack)
        target:delMod(xi.mod.RATT, attack)
    end
end

return effectObject
