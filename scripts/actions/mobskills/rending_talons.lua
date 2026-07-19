-----------------------------------
-- Rending Talons
-- Family: Harpeia
-- Description: Single-target physical damage, knockback, and TP reset.
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
        fTP            = { 3.0, 3.0, 3.0 },
        attackType     = xi.attackType.PHYSICAL,
        damageType     = xi.damageType.SLASHING,
        shadowBehavior = xi.mobskills.shadowBehavior.NUMSHADOWS_1,
    }

    local info = xi.mobskills.mobPhysicalMove(mob, target, skill, action, params)
    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
        target:setTP(0)
    end

    return info.damage
end

return mobskillObject
