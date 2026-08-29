-----------------------------------
-- Spell: Thunder Breath
-- Deals lightning damage to enemies within a fan-shaped area originating from the caster
-- Spell cost: 193 MP
-- Monster Type: Dragons
-- Spell Type: Magical (Breath/Lightning)
-- Blue Magic Points: 4
-- Stat Bonus: AGI+2
-- Level: 97
-- Casting Time: 7 seconds
-- Recast Time: 112 seconds
-- Combos: None
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params = {}
    params.ecosystem  = xi.ecosystem.DRAGON
    params.attackType = xi.attackType.BREATH
    params.damageType = xi.damageType.THUNDER
    params.diff       = 0
    params.skillType  = xi.skill.BLUE_MAGIC
    local blueSkill = caster:getSkillLevel(xi.skill.BLUE_MAGIC)
    local baseDamage = caster:getHP() / 3 + 4 * blueSkill + 6 * caster:getStat(xi.mod.VIT)
    local blueSkill = caster:getSkillLevel(xi.skill.BLUE_MAGIC)
    local baseDamage = caster:getHP() / 3 + 4 * blueSkill + 6 * caster:getStat(xi.mod.VIT)
    params.hpMod = caster:getHP() / baseDamage
    params.lvlMod = 0
    params.isConal    = true

    return xi.spells.blue.useBreathSpell(caster, target, spell, params)
end

return spellObject
