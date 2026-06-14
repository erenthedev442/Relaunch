-----------------------------------
-- Spell: Erratic Flutter
-- Grants Haste and Fast Cast
-- Spell cost: 92 MP
-- Monster Type: Vermin
-- Spell Type: Magical (Wind)
-- Blue Magic Points: 5
-- Stat Bonus: AGI+2
-- Level: 99
-- Casting Time: 1 second
-- Recast Time: 45 seconds
-- Duration: 5 minutes
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local duration = xi.spells.blue.calculateDurationWithDiffusion(caster, 300)

    target:addStatusEffect(xi.effect.HASTE,     { power = 30, duration = duration, origin = caster })
    target:addStatusEffect(xi.effect.FAST_CAST,  { power = 15, duration = duration, origin = caster })

    return xi.effect.HASTE
end

return spellObject
