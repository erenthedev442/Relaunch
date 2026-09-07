-----------------------------------
-- Inferno Blast
-- Family: Wyrms (Tiamat)
-- Description: Deals Fire damage to enemies in area of effect.
-- Notes: Used by Tiamat, Smok and Ildebrann while flying.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    if mob:getAnimationSub() ~= 1 then -- Only use while flying
        return 1
    end

    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.baseDamage     = mob:getMainLvl() + 2
    params.fTP            = { 7, 7, 7 }
    params.element        = xi.element.FIRE
    params.attackType     = xi.attackType.MAGICAL
    params.damageType     = xi.damageType.FIRE
    params.shadowBehavior = xi.mobskills.shadowBehavior.WIPE_SHADOWS

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)

    -- Voidspire Tiamat: fTP 7 + MATT ramp is ~11k. Cap just under 9k player HP.
    local voidCap = mob:getLocalVar('VoidspireInfernoBlastCap')
    if voidCap > 0 then
        info.damage = math.min(info.damage, voidCap)
    end

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
    end

    return info.damage
end

return mobskillObject
