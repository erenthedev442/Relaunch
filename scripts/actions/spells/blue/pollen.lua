-----------------------------------
-- Spell: Pollen
-- Restores HP
-- Spell cost: 8 MP
-- Monster Type: Vermin
-- Spell Type: Magical (Light)
-- Blue Magic Points: 1
-- Stat Bonus: CHR+1, HP+5
-- Level: 1
-- Casting Time: 2 seconds
-- Recast Time: 5 seconds
-----------------------------------
-- Combos: Resist Sleep
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    if xi.spells.blue.usesStockSubjobBehavior(caster) then
        return xi.spells.blue.useCuringSpell(caster, target, spell,
        {
            minCure         = 14,
            divisor0        = 1,
            constant0       = -6,
            powerThreshold1 = 59,
            divisor1        = 2,
            constant1       = 9,
            powerThreshold2 = 99,
            divisor2        = 57,
            constant2       = 33.125,
        })
    end

    return xi.spells.blue.applyBlueCure(caster, target, { base = 0, scale = 1.0 })
end

return spellObject
