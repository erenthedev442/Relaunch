-----------------------------------
-- Shared Rosulatia special auto-attack helpers
-- Tree Spike: Earth. Vines: Earth + Bind. Twister: Slashing + Silence.
-----------------------------------
local M = {}

local MS_SPIKE   = 3659
local MS_VINES   = 3660
local MS_TWISTER = 3661

M.onMobSkillCheck = function(target, mob, skill)
    if mob:checkDistance(target) > 7 then
        return 1
    end

    return 0
end

M.onMobWeaponSkill = function(mob, target, skill, action)
    local id = skill:getID()
    local params = {}
    params.primaryMessage = xi.msg.basic.HIT_DMG

    if id == MS_TWISTER then
        params.baseDamage     = mob:getWeaponDmg()
        params.numHits        = 1
        params.fTP            = { 1.0, 1.0, 1.0 }
        params.attackType     = xi.attackType.PHYSICAL
        params.damageType     = xi.damageType.SLASHING
        params.shadowBehavior = xi.mobskills.shadowBehavior.NUMSHADOWS_1

        local info = xi.mobskills.mobPhysicalMove(mob, target, skill, action, params)
        if xi.mobskills.processDamage(mob, target, skill, action, info) then
            target:takeDamage(info.damage, mob, info.attackType, info.damageType)
            xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.SILENCE, 1, 0, 30)
        end

        return info.damage
    end

    -- Tree Spike / Vines: earth elemental special AA (no MAB — AA lane).
    params.baseDamage         = mob:getWeaponDmg()
    params.fTP                = { 1.0, 1.0, 1.0 }
    params.element            = xi.element.EARTH
    params.attackType         = xi.attackType.MAGICAL
    params.damageType         = xi.damageType.EARTH
    params.shadowBehavior     = xi.mobskills.shadowBehavior.IGNORE_SHADOWS
    params.skipMagicBonusDiff = true

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)
    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)

        if id == MS_VINES then
            xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.BIND, 1, 0, 15)
        end
    end

    return info.damage
end

return M
