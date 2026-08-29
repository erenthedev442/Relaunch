-----------------------------------
-- Spell: Mortal Ray
-- Inflicts Doom on an enemy (gaze)
-- Spell cost: 267 MP
-- Monster Type: Demons
-- Spell Type: Magical (Dark)
-- Blue Magic Points: 5
-- Stat Bonus: MND+3
-- Level: 91
-- Casting Time: 8 seconds
-- Recast Time: 150 seconds
-- Duration: 63 seconds
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
    params.duration        = 63
    params.resistThreshold = 0.5
    params.isGaze          = true
    params.isConal         = false

    return xi.spells.blue.useEnfeeblingSpell(caster, target, spell, params)
end

return spellObject
