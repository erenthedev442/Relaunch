-----------------------------------
-- Meteoric Impact
-- Trust: Zazarg. AoE H2H. Additional effect: Petrification.
-- Skillchain: Darkness / Fragmentation.
-- C-tier bruiser fTP (signature move; not Victory Smite power).
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
    params.damageType     = xi.damageType.HTH
    params.shadowBehavior = xi.mobskills.shadowBehavior.NUMSHADOWS_1
    params.str_wSC        = 0.4
    params.vit_wSC        = 0.4

    local info = xi.mobskills.mobPhysicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
        -- Short Petrify; trust CC should not lock forever.
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.PETRIFICATION, 1, 0, 8)
    end

    return info.damage
end

return mobskillObject
