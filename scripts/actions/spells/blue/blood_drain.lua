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
-- Recast Time: 26 seconds
-- Magic Bursts on: Compression, Gravitation, Darkness
-- Combos: None
-- Heal scales with Blue skill + INT + MND. 4000 only with broken
-- stacked stats after MAB / weather / staff. No weapon-amp nuke scaling.
-----------------------------------
---@type TSpell
local spellObject = {}

spellObject.onMagicCastingCheck = function(caster, target, spell)
    return 0
end

spellObject.onSpellCast = function(caster, target, spell)
    local bluSharedEffects = require('modules/custom/lua/blu_shared_effects')
    local params = {}
    params.ecosystem = xi.ecosystem.BIRD
    params.attackType = xi.attackType.MAGICAL
    params.damageType = xi.damageType.DARK
    params.diff = 0 -- no stat increases magic accuracy
    params.skillType = xi.skill.BLUE_MAGIC
    params.blueDamageExempt = true
    params.drainHealCap = bluSharedEffects.BLOOD_DRAIN_HEAL_CAP
    local blueSkill = caster:getSkillLevel(xi.skill.BLUE_MAGIC)
    local skillBase = math.max(math.floor(blueSkill * 0.11), 1)
    local baseDamage = bluSharedEffects.bloodDrainBase(
        blueSkill, caster:getStat(xi.mod.INT), caster:getStat(xi.mod.MND))
    params.attribute = xi.mod.INT
    params.dmgMultiplier = baseDamage / skillBase

    return xi.spells.blue.useDrainSpell(caster, target, spell, params, bluSharedEffects.BLOOD_DRAIN_HEAL_CAP, false)
end

return spellObject
