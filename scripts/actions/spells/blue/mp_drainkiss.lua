-----------------------------------
-- Spell: MP Drainkiss
-- Steals an enemy's MP. Ineffective against undead
-- Spell cost: 20 MP
-- Monster Type: Amorphs
-- Spell Type: Magical (Dark)
-- Blue Magic Points: 4
-- Stat Bonus: MP+5
-- Level: 42
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
    params.ecosystem = xi.ecosystem.AMORPH
    params.attackType = xi.attackType.MAGICAL
    params.attribute = xi.mod.INT
    params.skillType = xi.skill.BLUE_MAGIC
    local blueSkill = caster:getSkillLevel(xi.skill.BLUE_MAGIC)
    local skillBase = math.max(math.floor(blueSkill * 0.11), 1)
    local baseDamage = 500 + 2 * blueSkill + 3 * caster:getStat(xi.mod.INT)
    params.attribute = xi.mod.INT
    local blueSkill = caster:getSkillLevel(xi.skill.BLUE_MAGIC)
    local skillBase = math.max(math.floor(blueSkill * 0.11), 1)
    local baseDamage = 500 + 2 * blueSkill + 3 * caster:getStat(xi.mod.INT)
    params.attribute = xi.mod.INT
    params.dmgMultiplier = baseDamage / skillBase

    return xi.spells.blue.useDrainSpell(caster, target, spell, params, 2000, true)
end

return spellObject
