-----------------------------------
-- Pocket Sand
-- Family: Qiqirn (Trust: Chacharoon)
-- Description: Conal earth magical damage + Blind (up to -50 Acc, 60s).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    -- Utility B path owns damage; keep fTP modest so AA/status kit stays the identity.
    params.baseDamage     = mob:getMainLvl() + 2
    params.fTP            = { 1.5, 1.75, 2.0 }
    params.element        = xi.element.EARTH
    params.attackType     = xi.attackType.MAGICAL
    params.damageType     = xi.damageType.EARTH
    params.shadowBehavior = xi.mobskills.shadowBehavior.IGNORE_SHADOWS

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.BLINDNESS, 50, 0, 60)
    end

    return info.damage
end

return mobskillObject
