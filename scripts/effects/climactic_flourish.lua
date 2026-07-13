-----------------------------------
-- xi.effect.CLIMACTIC_FLOURISH
--
-- RELAUNCH FIX 2026-07-13: stock LSB left this as a bare no-op stub; no
-- engine or Lua code checked for it during hit resolution, so the ability
-- did nothing on live. Now: while the effect is up, the wearer gets a
-- guaranteed critical hit (CRITHITRATE +100) at +50% crit damage
-- (CRIT_DMG_INCREASE +50), which matches retail Climactic's "next hit is
-- a crit + 50% base damage bonus". Any Maculele/Charis tiara mods that
-- grant crit rate / WSD stack on top through the normal item mod path.
-- The custom module climactic_flourish_consumer.lua drops the effect
-- after the next weaponskill so it behaves as a "next-WS" buff rather
-- than a 60-second free-crit window on autos.
-----------------------------------
---@type TEffect
local effectObject = {}

effectObject.onEffectGain = function(target, effect)
    target:addMod(xi.mod.CRITHITRATE,       100)
    target:addMod(xi.mod.CRIT_DMG_INCREASE,  50)
end

effectObject.onEffectTick = function(target, effect)
end

effectObject.onEffectLose = function(target, effect)
    target:delMod(xi.mod.CRITHITRATE,       100)
    target:delMod(xi.mod.CRIT_DMG_INCREASE,  50)
end

return effectObject
