-----------------------------------
-- Revelation
-- Empyreal Paradox Selh'teus (1510): light magical (story fight).
-- Trust Selh'teus (3623): Light magical WS fed by weapon rating.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

local MS_TRUST_REVELATION = 3623

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.element        = xi.element.LIGHT
    params.attackType     = xi.attackType.MAGICAL
    params.damageType     = xi.damageType.LIGHT
    params.shadowBehavior = xi.mobskills.shadowBehavior.IGNORE_SHADOWS

    if skill:getID() == MS_TRUST_REVELATION then
        params.baseDamage = mob:getWeaponDmg()
        params.fTP        = { 3.25, 3.75, 4.5 }
    else
        params.baseDamage = mob:getMainLvl() + 2
        params.fTP        = { 2.0, 2.0, 2.0 }
    end

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
    end

    return info.damage
end

return mobskillObject
