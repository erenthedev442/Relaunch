-----------------------------------
-- Spell: Mighty Guard
-- Grants Haste, Defense Boost, Magic Defense Boost, and Regen to party members within area of effect
-- Spell cost: 299 MP
-- Monster Type: Dragons
-- Spell Type: Magical (Light)
-- Blue Magic Points: 9
-- Stat Bonus: HP+5 STR+1
-- Level: 99
-- Casting Time: 3.5 seconds
-- Recast Time: 30 seconds
-- Duration: 3 minutes
-- Requires Unbridled Learning
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local duration = xi.spells.blue.calculateDurationWithDiffusion(caster, 180)

    target:addStatusEffect(xi.effect.HASTE,           { power = 1500, duration = duration, origin = caster })
    target:addStatusEffect(xi.effect.DEFENSE_BOOST,   { power = 25, duration = duration, origin = caster })
    target:addStatusEffect(xi.effect.MAGIC_DEF_BOOST, { power = 15, duration = duration, origin = caster })
    target:addStatusEffect(xi.effect.REGEN,           { power = 30, duration = duration, origin = caster })

    return xi.effect.HASTE
end

return spellObject
