-----------------------------------
-- Spell: Absolute Terror
-- Freezes an enemy with terror
-- Spell cost: 29 MP
-- Monster Type: Dragons
-- Spell Type: Magical (Dark)
-- Blue Magic Points: 3
-- Stat Bonus: HP+5 STR+1
-- Level: 96
-- Casting Time: 0.5 seconds
-- Recast Time: 30 seconds
-- Duration: 10 seconds
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
