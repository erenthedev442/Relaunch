-----------------------------------
-- Spell: Fantod
-- Enhances attack and magic attack. Effect is stackable (up to 10 times)
-- Spell cost: 12 MP
-- Monster Type: Lizards
-- Spell Type: Magical (Fire)
-- Blue Magic Points: 2
-- Stat Bonus: Store TP
-- Level: 85
-- Casting Time: 0.5 seconds
-- Recast Time: 10 seconds
-- Duration: Unknown (stackable)
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local duration = xi.spells.blue.calculateDurationWithDiffusion(caster, 180)

    caster:addStatusEffect(xi.effect.ATTACK_BOOST,    { power = 5,  duration = duration, origin = caster })
    caster:addStatusEffect(xi.effect.MAGIC_ATK_BOOST, { power = 5,  duration = duration, origin = caster })

    return xi.effect.ATTACK_BOOST
end

return spellObject
