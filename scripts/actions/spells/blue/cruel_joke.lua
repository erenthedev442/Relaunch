-----------------------------------
-- Spell: Cruel Joke
-- Inflicts Doom on enemies within area of effect
-- Spell cost: 187 MP
-- Monster Type: Demons
-- Spell Type: Magical (Dark)
-- Blue Magic Points: 5
-- Stat Bonus: MND+3
-- Level: 99
-- Casting Time: 3 seconds
-- Recast Time: 30 seconds
-- Duration: 60 seconds
-- Requires Unbridled Learning
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params = {}
    params.ecosystem       = xi.ecosystem.DEMON
    params.effect          = xi.effect.DOOM
    params.power           = 1
    params.tick            = 0
    params.duration        = 60
    params.resistThreshold = 0.5
    params.isGaze          = false
    params.isConal         = false

    return xi.spells.blue.useEnfeeblingSpell(caster, target, spell, params)
end

return spellObject
