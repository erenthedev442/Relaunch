-----------------------------------
-- Tongue Lash
-- Family: Humanoid (Trust: Rongelouts)
-- AoE physical. Additional Effect: Terror (~2s).
-- Skillchain: None.
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
    params.fTP            = { 2.5, 3.0, 3.5 }
    params.attackType     = xi.attackType.PHYSICAL
    params.damageType     = xi.damageType.SLASHING
    params.shadowBehavior = xi.mobskills.shadowBehavior.NUMSHADOWS_1
    params.str_wSC        = 0.4
    params.vit_wSC        = 0.2

    local info = xi.mobskills.mobPhysicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
        -- Retail Trust: short AoE Terror (~2s).
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.TERROR, 1, 0, 2)
    end

    return info.damage
end

return mobskillObject
