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
    local skill = caster:getSkillLevel(xi.skill.BLUE_MAGIC)
    local cure = 2000 + 2.5 * skill + 5 * caster:getStat(xi.mod.MND) + 2 * caster:getStat(xi.mod.VIT)
    cure = math.floor(math.min(cure, 5000, caster:getMaxHP() - caster:getHP()))

    caster:addHP(cure)
    caster:updateEnmityFromCure(caster, cure)
    return cure
end

return spellObject
