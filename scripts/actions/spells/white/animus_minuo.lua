-----------------------------------
-- Spell: Animus Minuo
-----------------------------------
-- RETAIL FIDELITY NOTE
--   RUN spell: reduces the target's elemental resistance corresponding to the caster's active rune. This implementation applies the ADDLE effect as a generic debuff -- true retail mechanic is per-element resistance down and needs more research.
-- TUNING
--   For proper retail fidelity, mirror the rune system: check caster's active rune (IGNIS/GELUS/FLABRA/etc.) and apply the corresponding xi.mod.XXX_RES_DOWN. Default here is a flat 30-power Addle-style debuff for 90s.
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local effect    = xi.effect.ADDLE
    local skillLvl  = caster:getSkillLevel(xi.skill.ENFEEBLING_MAGIC)
    local potency   = math.floor(skillLvl / 5) + 30
    local duration  = 90

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
