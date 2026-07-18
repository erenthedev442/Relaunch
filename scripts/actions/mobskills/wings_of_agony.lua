-----------------------------------
-- Wings of Agony
-- Family: Harpeia
-- Description: High AoE physical damage with Sleep and Paralysis.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params =
    {
        baseDamage     = mob:getWeaponDmg(),
        numHits        = 1,
        fTP            = { 4.0, 4.0, 4.0 },
        attackType     = xi.attackType.PHYSICAL,
        damageType     = xi.damageType.SLASHING,
        shadowBehavior = xi.mobskills.shadowBehavior.NUMSHADOWS_1,
    }

    local info = xi.mobskills.mobPhysicalMove(mob, target, skill, action, params)
    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.SLEEP_I, 1, 0, 30)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.PARALYSIS, 40, 0, 60)
    end

    return info.damage
end

return mobskillObject
