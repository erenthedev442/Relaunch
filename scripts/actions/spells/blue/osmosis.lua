-----------------------------------
-- Spell: Osmosis
-- Steals an enemy's HP and one beneficial status effect
-- Spell cost: 47 MP
-- Monster Type: Amorphs
-- Spell Type: Magical (Dark)
-- Blue Magic Points: 3
-- Stat Bonus: MND+1
-- Level: 84
-- Casting Time: 4 seconds
-- Recast Time: 120 seconds
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
    params.ecosystem     = xi.ecosystem.AMORPH
    params.attackType    = xi.attackType.MAGICAL
    params.damageType    = xi.damageType.DARK
    params.diff          = 0 -- no stat increases magic accuracy
    params.skillType     = xi.skill.BLUE_MAGIC
    local blueSkill = caster:getSkillLevel(xi.skill.BLUE_MAGIC)
    local skillBase = math.max(math.floor(blueSkill * 0.11), 1)
    local baseDamage = 1500 + 3 * blueSkill + 4 * caster:getStat(xi.mod.INT)
    params.attribute = xi.mod.INT
    local blueSkill = caster:getSkillLevel(xi.skill.BLUE_MAGIC)
    local skillBase = math.max(math.floor(blueSkill * 0.11), 1)
    local baseDamage = 1500 + 3 * blueSkill + 4 * caster:getStat(xi.mod.INT)
    params.attribute = xi.mod.INT
    params.dmgMultiplier = baseDamage / skillBase

    local damage = xi.spells.blue.useDrainSpell(caster, target, spell, params, 4000, false)

    -- Steal one beneficial status effect from target.
    if damage > 0 then
        target:dispelStatusEffect()
    end

    return damage
end

return spellObject
