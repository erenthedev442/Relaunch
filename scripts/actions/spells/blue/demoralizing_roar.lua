-----------------------------------
-- Spell: Demoralizing Roar
-- Lowers the attack of enemies within range
-- Spell cost: 46 MP
-- Monster Type: Beasts
-- Spell Type: Magical (Water)
-- Blue Magic Points: 3
-- Stat Bonus: VIT+1
-- Level: 80
-- Casting Time: 4 seconds
-- Recast Time: 20 seconds
-- Duration: 30 seconds
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params = {}
    params.ecosystem       = xi.ecosystem.BEAST
    params.effect          = xi.effect.ATTACK_DOWN
    params.power           = 20
    params.tick            = 0
    params.duration        = 30
    params.resistThreshold = 0.5
    params.isGaze          = false
    params.isConal         = false

    return xi.spells.blue.useEnfeeblingSpell(caster, target, spell, params)
end

return spellObject
