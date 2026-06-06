-----------------------------------
-- Spell: Moogle Rhapsody
-----------------------------------
-- RETAIL FIDELITY NOTE
--   BRD flavor song. Retail mechanic unclear -- placeholder/event. This implementation applies a small Refresh effect themed around moogles.
-- TUNING
--   Adjust effect / potency if retail behavior is something else. Default is REFRESH at potency 2, 3-min duration.
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local effect    = xi.effect.REFRESH
    local potency   = 2
    local duration  = 180

    if target:addStatusEffect(effect, potency, 0, duration) then
        spell:setMsg(xi.msg.basic.MAGIC_GAIN_EFFECT)
    else
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
    end
    return effect
end

return spellObject
