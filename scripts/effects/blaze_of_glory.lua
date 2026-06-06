-----------------------------------
-- xi.effect.BLAZE_OF_GLORY
--
-- Repurposed for the custom "Bouncer" tank job (GEO/job 21 slot) as the
-- "Brace" damage-taken-reduction buff.  While active it lowers DMG taken by
-- the effect's power (10000 = 100%); the Bouncer's Brace override applies it
-- with power = BRACE_DMG_REDUCTION (see modules/custom/lua/bouncer_abilities.lua).
--
-- Stock GEO's Blaze of Glory applies this effect with NO power (power = 0), so
-- for any non-Bouncer user this script is a harmless no-op (addMod DMG -0).
-- That is why this additive file is safe to ship: it completes a latent stock
-- gap (LSB ships no effect script for BLAZE_OF_GLORY) without changing GEO.
--
-- Mirrors the canonical DMG-down effect pattern (see effects/gallants_roll.lua).
-----------------------------------
---@type TEffect
local effectObject = {}

effectObject.onEffectGain = function(target, effect)
    target:addMod(xi.mod.DMG, -effect:getPower())
end

effectObject.onEffectTick = function(target, effect)
end

effectObject.onEffectLose = function(target, effect)
    target:delMod(xi.mod.DMG, -effect:getPower())
end

return effectObject
