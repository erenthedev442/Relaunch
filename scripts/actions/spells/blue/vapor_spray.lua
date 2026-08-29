-----------------------------------
-- Spell: Vapor Spray
-- Deals water damage to enemies within a fan-shaped area originating from the caster
-- Spell cost: 172 MP
-- Monster Type: Aquans
-- Spell Type: Magical (Breath/Water)
-- Blue Magic Points: 4
-- Stat Bonus: MND+2
-- Level: 96
-- Casting Time: 3 seconds
-- Recast Time: 56 seconds
-- Combos: None
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params = {}
    params.ecosystem  = xi.ecosystem.AQUAN
    params.attackType = xi.attackType.BREATH
    params.damageType = xi.damageType.WATER
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
