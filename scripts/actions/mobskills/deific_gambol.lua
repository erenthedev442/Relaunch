-----------------------------------
-- Deific Gambol
-- Trust Ygnas (3815) / Sinister Reign Ygnas (2982):
-- AoE Light magical damage + light DoT (Dia-like).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

local MS_TRUST = 3815

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.element        = xi.element.LIGHT
    params.attackType     = xi.attackType.MAGICAL
    params.damageType     = xi.damageType.LIGHT
    params.shadowBehavior = xi.mobskills.shadowBehavior.WIPE_SHADOWS
    params.mnd_wSC        = 0.3

    -- AoE: slightly lower fTP than Sacred Caper.
    if skill:getID() == MS_TRUST then
        params.baseDamage = mob:getWeaponDmg()
        params.fTP        = { 2.5, 3.0, 3.75 }
    else
        params.baseDamage = mob:getMainLvl() + 2
        params.fTP        = { 2.0, 2.0, 2.0 }
    end

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.DIA, 8, 3, 60)
    end

    return info.damage
end

return mobskillObject
