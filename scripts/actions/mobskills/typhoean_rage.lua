-----------------------------------
-- Typhoean Rage
-- Family: Harpeia
-- Description: AoE wind damage with Amnesia, Encumbrance, and Muddle.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return mob:getHPP() > 50 and 1 or 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params =
    {
        baseDamage     = mob:getMainLvl() + 2,
        fTP            = { 4.5, 4.5, 4.5 },
        element        = xi.element.WIND,
        attackType     = xi.attackType.MAGICAL,
        damageType     = xi.damageType.WIND,
        shadowBehavior = xi.mobskills.shadowBehavior.WIPE_SHADOWS,
    }

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)
    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.AMNESIA, 1, 0, 60)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.ENCUMBRANCE_II, 0xFFFF, 0, 60)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.MUDDLE, 1, 0, 60)
    end

    return info.damage
end

return mobskillObject
