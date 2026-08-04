-----------------------------------
-- Akimbo Shot
-- Family: Humanoid (Luzaf)
-- Description: Marksmanship weaponskill. Twofold attack; damage varies with TP.
-- Skillchain Properties: Reverberation / Detonation
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.baseDamage        = mob:getWeaponDmg()
    params.numHits           = 2
    params.fTP               = { 2.25, 2.75, 3.25 }
    params.fTPSubsequentHits = { 2.25, 2.75, 3.25 }
    params.skipParry         = true
    params.skipGuard         = true
    params.skipBlock         = true
    params.attackType        = xi.attackType.RANGED
    params.damageType        = xi.damageType.PIERCING
    params.shadowBehavior    = xi.mobskills.shadowBehavior.NUMSHADOWS_2

    local info = xi.mobskills.mobRangedMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
    end

    return info.damage
end

return mobskillObject
