-----------------------------------
-- Coming Up Roses
-- Family: Humanoid (Mayakov)
-- Description: Delivers a beautiful blow to the target. Damage varies with TP.
-- Skillchain Properties: Light / Fusion
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    -- Retail note: unusually strong for a Trust WS. C-tier softclamp still gates.
    params.baseDamage     = mob:getWeaponDmg()
    params.numHits        = 3
    params.fTP            = { 3.25, 4.0, 4.75 }
    params.attackType     = xi.attackType.PHYSICAL
    params.damageType     = xi.damageType.SLASHING
    params.shadowBehavior = xi.mobskills.shadowBehavior.NUMSHADOWS_3
    params.canCrit        = true

    local info = xi.mobskills.mobPhysicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
    end

    return info.damage
end

return mobskillObject
