-----------------------------------
-- Typhonic Arrow
-- Trust: Najelith. Conal Archery. Additional effect: Bind.
-- Skillchain: Light / Distortion.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}
    local rangedDmg = mob:getRangedDmg()

    params.baseDamage     = (rangedDmg > 0) and rangedDmg or mob:getWeaponDmg()
    params.numHits        = 1
    -- B-tier signature conal; not Empyreal power.
    params.fTP            = { 2.5, 3.0, 3.5 }
    params.skipParry      = true
    params.skipGuard      = true
    params.skipBlock      = true
    params.attackType     = xi.attackType.RANGED
    params.damageType     = xi.damageType.PIERCING
    params.shadowBehavior = xi.mobskills.shadowBehavior.NUMSHADOWS_1

    local info = xi.mobskills.mobRangedMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.BIND, 1, 0, 12)
    end

    return info.damage
end

return mobskillObject
