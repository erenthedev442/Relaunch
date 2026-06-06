-----------------------------------
-- Spell: Devotee Serenade
-----------------------------------
-- RETAIL FIDELITY NOTE
--   BRD flavor song. Devotion themed -- applies an MND boost.
-- TUNING
--   Adjust the boost effect / magnitude if needed.
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local effect    = xi.effect.MND_BOOST
    local skillLvl  = caster:getSkillLevel(xi.skill.SINGING)
    local potency   = math.floor(skillLvl / 4) + 5
    local duration  = 180

    if target:addStatusEffect(effect, potency, 0, duration) then
        spell:setMsg(xi.msg.basic.MAGIC_GAIN_EFFECT)
    else
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
    end
    return effect
end

return spellObject
