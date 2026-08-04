-----------------------------------
-- Amatsu: Hanaikusa
-- Story Tenzen (1394): Kasha variant + Paralysis.
-- Trust Tenzen: same skill ID; C-tier fTP (solo SC close Light).
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
        params.fTP = { 2.5, 3.0, 3.75 }
    else
        params.fTP = { 6.0, 6.0, 6.0 }
    end

    local info = xi.mobskills.mobPhysicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.PARALYSIS, 22, 0, 60)
    end

    return info.damage
end

return mobskillObject
