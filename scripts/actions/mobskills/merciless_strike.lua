-----------------------------------
-- Merciless Strike
-- Family: Humanoid (Trust: Ingrid / Ingrid II)
-- Description: Club WS correlating to True Strike. Critical damage; accuracy varies with TP.
-- Skillchain: Impaction (Light-building lane with Inexorable Strike).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.baseDamage       = mob:getWeaponDmg()
    params.numHits          = 1
    params.fTP              = { 1.0, 1.0, 1.0 }
    params.canCrit          = true
    params.criticalChance   = { 1.0, 1.0, 1.0 }
    params.accuracyModifier = { -50, -25, 0 }
    params.attackMultiplier = { 2.0, 2.0, 2.0 }
    params.attackType       = xi.attackType.PHYSICAL
    params.damageType       = xi.damageType.BLUNT
    params.shadowBehavior   = xi.mobskills.shadowBehavior.NUMSHADOWS_1

    local info = xi.mobskills.mobPhysicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
    end

    return info.damage
end

return mobskillObject
