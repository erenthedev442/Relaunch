-----------------------------------
-- Spell: Animus Augeo
-----------------------------------
-- RETAIL FIDELITY NOTE
--   RUN spell: amplifies the potency of the caster's active rune. Retail effect varies by which rune is up; this implementation applies a generic ATTACK_BOOST that approximates the average benefit across rune types.
-- TUNING
--   If you want per-rune behavior (Ignis -> fire attack, Gelus -> ice attack, etc.), check caster:getStatusEffect(xi.effect.IGNIS) / GELUS / etc. and branch the effect/magnitude accordingly. Default is a flat 25-power Attack Boost for 60s.
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local effect    = xi.effect.ATTACK_BOOST
    local skillLvl  = caster:getSkillLevel(xi.skill.ENHANCING_MAGIC)
    local potency   = math.floor(skillLvl / 8) + 25
    local duration  = 60

    if caster:addStatusEffect(effect, potency, 0, duration) then
        spell:setMsg(xi.msg.basic.MAGIC_GAIN_EFFECT)
    else
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
    end
    return effect
end

return spellObject
