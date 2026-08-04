-----------------------------------
-- Amatsu: Yukiarashi
-- Story Tenzen (1392): Yukikaze variant + Blind.
-- Trust Tenzen: same skill ID; C-tier fTP (solo SC open).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.baseDamage     = mob:getWeaponDmg()
    params.numHits        = 1
    params.attackType     = xi.attackType.PHYSICAL
    params.damageType     = xi.damageType.SLASHING
    params.shadowBehavior = xi.mobskills.shadowBehavior.NUMSHADOWS_1

    if mob:getObjType() == xi.objType.TRUST then
        params.fTP = { 2.25, 2.75, 3.5 }
    else
        params.fTP = { 6.0, 6.0, 6.0 }
    end

    local info = xi.mobskills.mobPhysicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.BLINDNESS, 1, 0, 60)
    end

    return info.damage
end

return mobskillObject
