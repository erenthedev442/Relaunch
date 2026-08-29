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
    local skill = caster:getSkillLevel(xi.skill.BLUE_MAGIC)
    local cure = math.min(1100 + 1.8 * skill + 4 * caster:getStat(xi.mod.MND), 2800)
    cure = math.floor(math.min(cure, target:getMaxHP() - target:getHP()))

    target:addHP(cure)
    caster:updateEnmityFromCure(target, cure)
    return cure
end

return spellObject
