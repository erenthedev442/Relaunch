-----------------------------------
-- Cosmic Breath
-- Family: Shinryu
-- Description: Deals light breath damage in a frontal cone.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.percentMultipier = 0.22
    params.damageCap        = 2600
    params.bonusDamage      = 0
    params.mAccuracyBonus   = { 200, 300, 400 }
    params.resistStat       = xi.mod.INT
    params.element          = xi.element.LIGHT
    params.attackType       = xi.attackType.BREATH
    params.damageType       = xi.damageType.LIGHT
    params.shadowBehavior   = xi.mobskills.shadowBehavior.IGNORE_SHADOWS

    local info = xi.mobskills.mobBreathMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
    end

    return info.damage
end

return mobskillObject
