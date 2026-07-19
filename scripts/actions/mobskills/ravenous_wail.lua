-----------------------------------
-- Ravenous Wail
-- Family: Harpeia
-- Description: AoE wind damage to HP/MP with Terror and Silence.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params =
    {
        baseDamage     = mob:getMainLvl() + 2,
        fTP            = { 4.0, 4.0, 4.0 },
        element        = xi.element.WIND,
        attackType     = xi.attackType.MAGICAL,
        damageType     = xi.damageType.WIND,
        shadowBehavior = xi.mobskills.shadowBehavior.WIPE_SHADOWS,
    }

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)
    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
        target:delMP(math.floor(info.damage / 2))
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.TERROR, 1, 0, 5)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.SILENCE, 1, 0, 60)
    end

    return info.damage
end

return mobskillObject
