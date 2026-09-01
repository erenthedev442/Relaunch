-----------------------------------
-- Spell: Restoral
-- Restores the caster's HP
-- Spell cost: 127 MP
-- Monster Type: Aquans
-- Spell Type: Magical (Light)
-- Blue Magic Points: 5
-- Stat Bonus: HP+15 MP+15
-- Level: 99
-- Casting Time: 2 seconds
-- Recast Time: 10 seconds
-- Combos: Max HP Boost
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.spells.blue.applyBlueCure(caster, caster, { base = 100, scale = 1.90 })
end

return spellObject
