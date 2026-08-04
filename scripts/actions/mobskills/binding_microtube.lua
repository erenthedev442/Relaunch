-----------------------------------
-- Binding Microtube
-- Trust: Adelheid. Magical. Additional effect: Bind.
-- Skillchain: Gravitation / Induration.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.baseDamage       = mob:getWeaponDmg()
    params.fTP              = { 1.75, 2.25, 2.75 }
    params.element          = xi.element.EARTH
    params.attackType       = xi.attackType.MAGICAL
    params.damageType       = xi.damageType.EARTH
    params.shadowBehavior   = xi.mobskills.shadowBehavior.IGNORE_SHADOWS
    params.dStatMultiplier  = 1
    params.dStatAttackerMod = xi.mod.INT
    params.dStatDefenderMod = xi.mod.INT

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.BIND, 1, 0, 20)
    end

    return info.damage
end

return mobskillObject
