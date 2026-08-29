-----------------------------------
-- Spell: Exuviation
-- Restores HP and removes one detrimental magic effect
-- Spell cost: 40 MP
-- Monster Type: Vermin
-- Spell Type: Magical (Fire)
-- Blue Magic Points: 4
-- Stat Bonus: HP+5 MP+5 CHR+1
-- Level: 75
-- Casting Time: 3 seconds
-- Recast Time: 60 seconds
-----------------------------------
-- Combos: Resist Sleep
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    target:eraseStatusEffect()
    target:eraseStatusEffect()

    local skill = caster:getSkillLevel(xi.skill.BLUE_MAGIC)
    local cure = math.min(1500 + 2 * skill + 4 * caster:getStat(xi.mod.MND), 3500)
    cure = math.min(cure, target:getMaxHP() - target:getHP())

    target:addHP(cure)
    caster:updateEnmityFromCure(target, cure)
    return cure
end

return spellObject
