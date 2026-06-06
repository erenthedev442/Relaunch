-----------------------------------
-- Spell: Chocobo Hum
-----------------------------------
-- RETAIL FIDELITY NOTE
--   BRD flavor song. Retail mechanic unclear -- likely a placeholder/joke song. This implementation applies a small Regen effect themed around chocobos.
-- TUNING
--   If the song should do something different (or nothing at all), adjust the effect / potency. Default is REGEN at potency 3, 3-min duration.
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local effect    = xi.effect.REGEN
    local potency   = 3
    local duration  = 180

    if target:addStatusEffect(effect, potency, 0, duration) then
        spell:setMsg(xi.msg.basic.MAGIC_GAIN_EFFECT)
    else
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
    end
    return effect
end

return spellObject
