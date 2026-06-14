-----------------------------------
-- Spell: Blistering Roar
-- Inflicts Terror on enemies within area of effect
-- Spell cost: 43 MP
-- Monster Type: Dragons
-- Spell Type: Magical (Dark)
-- Blue Magic Points: 4
-- Stat Bonus: STR+2
-- Level: 99
-- Casting Time: 0.5 seconds
-- Recast Time: 120 seconds
-- Duration: 5 seconds
-- Requires Unbridled Learning
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params = {}
    params.ecosystem       = xi.ecosystem.DRAGON
    params.effect          = xi.effect.TERROR
    params.power           = 1
    params.tick            = 0
    params.duration        = 5
    params.resistThreshold = 0.5
    params.isGaze          = false
    params.isConal         = false

    return xi.spells.blue.useEnfeeblingSpell(caster, target, spell, params)
end

return spellObject
