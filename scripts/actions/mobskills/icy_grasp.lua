-----------------------------------
-- Icy Grasp
-- Hades v1. Ice damage, animation 2401 (look 2674).
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
        fTP            = { 2.5, 2.5, 2.5 },
        element        = xi.element.ICE,
        attackType     = xi.attackType.MAGICAL,
        damageType     = xi.damageType.ICE,
        shadowBehavior = xi.mobskills.shadowBehavior.WIPE_SHADOWS,
    }

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)
    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
    end

    return info.damage
end

return mobskillObject
