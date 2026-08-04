-----------------------------------
-- Dynastic Gravitas
-- Trust Arciela (3451): AoE damage + Amnesia. Shadows stance only.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

local MS_TRUST = 3451
local STANCE_SHADOWS = 2

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    if skill:getID() == MS_TRUST and mob:getLocalVar('ArcielaStance') ~= STANCE_SHADOWS then
        return 1
    end

    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.element        = xi.element.DARK
    params.attackType     = xi.attackType.MAGICAL
    params.damageType     = xi.damageType.DARK
    params.shadowBehavior = xi.mobskills.shadowBehavior.WIPE_SHADOWS
    params.baseDamage     = mob:getWeaponDmg()
    params.fTP            = { 2.5, 3.0, 3.75 }
    params.mnd_wSC        = 0.3

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.AMNESIA, 1, 0, 30)
    end

    return info.damage
end

return mobskillObject
