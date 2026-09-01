-----------------------------------
-- Spell: Healing Breeze
-- Restores HP for party members within area of effect
-- Spell cost: 55 MP
-- Monster Type: Beasts
-- Spell Type: Magical (Wind)
-- Blue Magic Points: 4
-- Stat Bonus: CHR+2, HP+10
-- Level: 16
-- Casting Time: 4.5 seconds
-- Recast Time: 15 seconds
-----------------------------------
-- Combos: Auto Regen
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
            minCure         = 60,
            divisor0        = 0.6666,
            constant0       = -45,
            powerThreshold1 = 219,
            divisor1        = 2,
            constant1       = 65,
            powerThreshold2 = 459,
            divisor2        = 6.5,
            constant2       = 144.6666,
        })
    end

    return xi.spells.blue.applyBlueCure(caster, target, { base = 30, scale = 1.10 })
end

return spellObject
