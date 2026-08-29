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
    local skill = caster:getSkillLevel(xi.skill.BLUE_MAGIC)
    local cure = math.min(0.65 * caster:getMaxHP() + 1.5 * skill, 4500)
    cure = math.floor(math.min(cure, target:getMaxHP() - target:getHP()))

    target:addHP(cure)
    caster:updateEnmityFromCure(target, cure)
    return cure
end

return spellObject
