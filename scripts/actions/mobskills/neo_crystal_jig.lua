-----------------------------------
-- Neo Crystal Jig
-- Trust: Mumor II. Magical ice dance. Skillchain: Distortion.
-- Fever sequence step 1.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.baseDamage       = mob:getWeaponDmg()
    params.fTP              = { 2.25, 2.75, 3.25 }
    params.element          = xi.element.ICE
    params.attackType       = xi.attackType.MAGICAL
    params.damageType       = xi.damageType.ICE
    params.shadowBehavior   = xi.mobskills.shadowBehavior.WIPE_SHADOWS
    params.dStatMultiplier  = 1
    params.dStatAttackerMod = xi.mod.INT
    params.dStatDefenderMod = xi.mod.INT

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
    end

    return info.damage
end

return mobskillObject
