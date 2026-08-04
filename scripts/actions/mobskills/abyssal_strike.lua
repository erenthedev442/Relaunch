-----------------------------------
-- Abyssal Strike
-- Family: Humanoid (Zeid / Trust: Zeid / Shadow of Rage)
-- Description: Physical damage. Additional effect: Stun.
-- No skillchain properties.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}
    local isTrust = mob:getObjType() == xi.objType.TRUST

    params.baseDamage     = mob:getWeaponDmg()
    params.numHits        = 1
    -- Trust A-tier weaponskill path; story Zeid retains heavier fTP.
    params.fTP            = isTrust and { 2.5, 2.75, 3.0 } or { 4.7, 4.7, 4.7 }
    params.attackType     = xi.attackType.PHYSICAL
    params.damageType     = xi.damageType.SLASHING
    params.shadowBehavior = xi.mobskills.shadowBehavior.NUMSHADOWS_1

    local info = xi.mobskills.mobPhysicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.STUN, 1, 0, isTrust and 6 or 15)
    end

    return info.damage
end

return mobskillObject
