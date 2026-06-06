-----------------------------------
-- Spell: Cactuar Fugue
-----------------------------------
-- RETAIL FIDELITY NOTE
--   BRD flavor song. Cactuar themed (1000 Needles, spikes); applies an Attack Boost.
-- TUNING
--   Adjust if retail expects spikes / damage-on-hit instead. Default is ATTACK_BOOST at potency tied to Singing skill, 3-min duration.
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local effect    = xi.effect.ATTACK_BOOST
    local skillLvl  = caster:getSkillLevel(xi.skill.SINGING)
    local potency   = math.floor(skillLvl / 5)
    local duration  = 180

    if target:addStatusEffect(effect, potency, 0, duration) then
        spell:setMsg(xi.msg.basic.MAGIC_GAIN_EFFECT)
    else
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
    end
    return effect
end

return spellObject
