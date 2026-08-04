-----------------------------------
-- Sacred Caper
-- Trust Ygnas (3812) / Sinister Reign Ygnas (2979):
-- Light magical damage + Rasp.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

local MS_TRUST = 3812

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.element        = xi.element.LIGHT
    params.attackType     = xi.attackType.MAGICAL
    params.damageType     = xi.damageType.LIGHT
    params.shadowBehavior = xi.mobskills.shadowBehavior.IGNORE_SHADOWS
    params.mnd_wSC        = 0.3

    if skill:getID() == MS_TRUST then
        params.baseDamage = mob:getWeaponDmg()
        params.fTP        = { 3.0, 3.5, 4.25 }
    else
        params.baseDamage = mob:getMainLvl() + 2
        params.fTP        = { 2.5, 2.5, 2.5 }
    end

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.RASP, 25, 3, 60)
    end

    return info.damage
end

return mobskillObject
