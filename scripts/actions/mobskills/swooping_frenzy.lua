-----------------------------------
-- Swooping Frenzy
-- Family: Tulfaire
-- Description: Deals conal physical damage. Additional Effects: Defense Down,
-- Magic Defense Down.
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
    params.fTP            = { 3.0, 3.0, 3.0 }
    params.attackType     = xi.attackType.PHYSICAL
    params.damageType     = xi.damageType.PIERCING
    params.shadowBehavior = xi.mobskills.shadowBehavior.NUMSHADOWS_2

    local info = xi.mobskills.mobPhysicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)

        local duration = math.min(150, xi.mobskills.calculateDuration(skill:getTP(), 60, 150))
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.DEFENSE_DOWN, 25, 0, duration)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.MAGIC_DEF_DOWN, 25, 0, duration)
    end

    return info.damage
end

return mobskillObject
