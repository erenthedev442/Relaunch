-----------------------------------
-- Spell: Carcharian Verve
-- Enhances attack, magic attack, and grants Aquaveil
-- Spell cost: 65 MP
-- Monster Type: Aquans
-- Spell Type: Magical (Water)
-- Blue Magic Points: 5
-- Stat Bonus: HP+5 MND+2
-- Level: 99
-- Casting Time: 2 seconds
-- Recast Time: 60 seconds
-- Duration: 15 minutes
-- Requires Unbridled Learning
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local duration = xi.spells.blue.calculateDurationWithDiffusion(caster, 300)

    caster:addStatusEffect(xi.effect.ATTACK_BOOST,    { power = 40, duration = duration, origin = caster })
    caster:addStatusEffect(xi.effect.MAGIC_ATK_BOOST, { power = 40, duration = duration, origin = caster })
    caster:addStatusEffect(xi.effect.AQUAVEIL,        { power = 30, duration = duration, origin = caster })

    return xi.effect.ATTACK_BOOST
end

return spellObject
