-----------------------------------
-- Spell: Addle II
-----------------------------------
-- RETAIL FIDELITY NOTE
--   Upgraded Addle: same primary effect (slows enemy casting + reduces magic accuracy) with stronger magnitude. Effect ID re-uses xi.effect.ADDLE since no ADDLE_II effect exists in scripts/enum/effect.lua.
-- TUNING
--   Magnitude bumped ~50% over Addle I. Adjust the `+ 20` term if Addle II should be stronger / weaker.
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local effect    = xi.effect.ADDLE
    local skillLvl  = caster:getSkillLevel(xi.skill.ENFEEBLING_MAGIC)
    local potency   = math.floor(skillLvl / 4) + 20    -- Addle I is /5 + 10; II bumps +50%
    local duration  = 120

    if target:hasStatusEffect(effect) then
        target:delStatusEffect(effect)
    end

    if target:addStatusEffect(effect, potency, 0, duration) then
        spell:setMsg(xi.msg.basic.MAGIC_ENFEEB)
    else
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
    end
    return effect
end

return spellObject
