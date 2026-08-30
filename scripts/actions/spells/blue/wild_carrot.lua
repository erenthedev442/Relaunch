-----------------------------------
-- Spell: Wild Carrot
-- Restores HP for the target party member
-- Spell cost: 37 MP
-- Monster Type: Beasts
-- Spell Type: Magical (Light)
-- Blue Magic Points: 3
-- Stat Bonus: HP+5
-- Level: 30
-- Casting Time: 2.5 seconds
-- Recast Time: 6 seconds
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
            minCure         = 120,
            divisor0        = 1,
            constant0       = 60,
            powerThreshold1 = 179,
            divisor1        = 2,
            constant1       = 105,
            powerThreshold2 = 299,
            divisor2        = 15.6666,
            constant2       = 170.43,
        })
    end

    local skill = caster:getSkillLevel(xi.skill.BLUE_MAGIC)
    local cure = math.min(1200 + 2 * skill + 5 * caster:getStat(xi.mod.MND), 3200)
    cure = math.min(cure, target:getMaxHP() - target:getHP())

    target:addHP(cure)
    caster:updateEnmityFromCure(target, cure)
    return cure
end

return spellObject
