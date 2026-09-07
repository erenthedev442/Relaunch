-----------------------------------
-- Thunderstrike
-- Family: Khimaira
-- Description: Deals Thunder damage in an area of effect. Additional Effect: Stun
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.baseDamage     = mob:getMainLvl() + 2
    params.fTP            = { 9.00, 9.00, 9.00 } -- TODO: Capture fTPs
    params.element        = xi.element.THUNDER
    params.attackType     = xi.attackType.MAGICAL
    params.damageType     = xi.damageType.THUNDER
    params.shadowBehavior = xi.mobskills.shadowBehavior.IGNORE_SHADOWS -- TODO: Capture shadowBehavior
    params.canMagicBurst  = true

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)

    -- Voidspire Khimaira: same MATT ramp that pushed Fulmination to ~19k.
    local voidCap = mob:getLocalVar('VoidspireThunderstrikeCap')
    if voidCap > 0 then
        info.damage = math.min(info.damage, voidCap)
    end

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)

        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.STUN, 1, 0, math.random(6, 10))
    end

    return info.damage
end

return mobskillObject
