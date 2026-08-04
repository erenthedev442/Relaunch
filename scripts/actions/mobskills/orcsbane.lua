-----------------------------------
-- Orcsbane
-- Family: Humanoid (Trust: Excenmille (S))
-- Description: AoE physical damage. Enhanced vs Orcs.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

-- Orc / Orcish families (mob_pools.family).
local ORC_FAMILIES =
{
    [139] = true,
    [143] = true,
}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}
    local ftp    = { 2.0, 2.5, 3.0 }

    if ORC_FAMILIES[target:getFamily()] then
        ftp = { 3.0, 3.75, 4.5 }
    end

    params.baseDamage     = mob:getWeaponDmg()
    params.numHits        = 1
    params.fTP            = ftp
    params.attackType     = xi.attackType.PHYSICAL
    params.damageType     = xi.damageType.SLASHING
    params.shadowBehavior = xi.mobskills.shadowBehavior.NUMSHADOWS_1
    params.str_wSC        = 0.4
    params.vit_wSC        = 0.2

    local info = xi.mobskills.mobPhysicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
    end

    return info.damage
end

return mobskillObject
