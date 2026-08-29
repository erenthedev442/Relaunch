-----------------------------------
-- Spell: Winds of Promy.
-- Removes one detrimental magic effect for party members within area of effect
-- Spell cost: 36 MP
-- Monster Type: Empty
-- Spell Type: Magical (Light)
-- Blue Magic Points: 3
-- Stat Bonus: MND+3 CHR-2
-- Level: 89
-- Casting Time: 3 seconds
-- Recast Time: 20 seconds
-- Combos: Auto Refresh
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local firstEffect = target:eraseStatusEffect(false)
    local secondEffect = target:eraseStatusEffect(false)

    return firstEffect ~= xi.effect.NONE and firstEffect or secondEffect
end

return spellObject
