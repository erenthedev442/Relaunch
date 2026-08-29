-----------------------------------
-- Spell: Nature's Meditation
-- Enhances attack
-- Spell cost: 38 MP
-- Monster Type: Beasts
-- Spell Type: Magical (Fire)
-- Blue Magic Points: 2
-- Stat Bonus: Accuracy Bonus
-- Level: 99
-- Casting Time: 1 second
-- Recast Time: 60 seconds
-- Duration: 90 seconds
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local duration = xi.spells.blue.calculateDurationWithDiffusion(caster, 180)

    if not caster:addStatusEffect(xi.effect.ATTACK_BOOST, { power = 40, duration = duration, origin = caster }) then
        spell:setMsg(xi.msg.basic.MAGIC_NO_EFFECT)
    end

    return xi.effect.ATTACK_BOOST
end

return spellObject
