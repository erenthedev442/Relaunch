-----------------------------------
-- Spell: White Wind
-- Restores HP of all party members within area of effect.
-- Spell cost: 145 MP
-- Monster Type: Dragon
-- Spell Type: Magical (Wind)
-- Blue Magic Points: 5
-- Stat Bonus: HP+5 AGI+1
-- Level: 94
-- Casting Time: 7 seconds
-- Recast Time: 20 seconds
-----------------------------------
-- Combos: Auto Regen
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    return xi.spells.blue.applyBlueCure(caster, target, { base = 60, scale = 1.55, hp = 0.05 })
end

return spellObject
