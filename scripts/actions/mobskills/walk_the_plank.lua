-----------------------------------
-- Walk the Plank
-- Family: Humanoid (Lion)
-- Description: AoE Damage, Bind, Knockback, dispel
-- Skillchain Properties: Light/Distortion
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
    -- Was stub 0.3 fTP (Walk the Plank did ~170). Trust Lion/Lion II finisher.
    params.fTP            = { 3.5, 4.25, 5.0 }
    params.attackType     = xi.attackType.PHYSICAL
    params.damageType     = xi.damageType.PIERCING
    params.shadowBehavior = xi.mobskills.shadowBehavior.NUMSHADOWS_3 -- TODO: Capture shadowBehavior

    local info = xi.mobskills.mobPhysicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)

        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.BIND, 1, 0, 20) -- TODO: Capture duration

        target:dispelStatusEffect()
    end

    return info.damage
end

return mobskillObject
