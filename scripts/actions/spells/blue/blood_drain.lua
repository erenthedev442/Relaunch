-----------------------------------
-- Spell: Blood Drain
-- Steals an enemy's HP. Ineffective against undead
-- Spell cost: 10 MP
-- Monster Type: Birds
-- Spell Type: Magical (Dark)
-- Blue Magic Points: 2
-- Stat Bonus: HP-5, MP+5
-- Level: 20
-- Casting Time: 4 seconds
-- Recast Time: 90 seconds
-- Magic Bursts on: Compression, Gravitation, Darkness
-- Combos: None
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local params = {}
    params.ecosystem = xi.ecosystem.BIRD
    params.attackType = xi.attackType.MAGICAL
    params.damageType = xi.damageType.DARK
    params.diff = 0 -- no stat increases magic accuracy
    params.skillType = xi.skill.BLUE_MAGIC
    local blueSkill = caster:getSkillLevel(xi.skill.BLUE_MAGIC)
    local skillBase = math.max(math.floor(blueSkill * 0.11), 1)
    local baseDamage = 900 + 2.5 * blueSkill + 3 * caster:getStat(xi.mod.INT)
    params.attribute = xi.mod.INT
    local blueSkill = caster:getSkillLevel(xi.skill.BLUE_MAGIC)
    local skillBase = math.max(math.floor(blueSkill * 0.11), 1)
    local baseDamage = 900 + 2.5 * blueSkill + 3 * caster:getStat(xi.mod.INT)
    params.attribute = xi.mod.INT
    params.dmgMultiplier = baseDamage / skillBase

    return xi.spells.blue.useDrainSpell(caster, target, spell, params, 2500, false)
end

return spellObject
