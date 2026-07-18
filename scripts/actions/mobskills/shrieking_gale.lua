-----------------------------------
-- Shrieking Gale
-- Family: Harpeia
-- Description: AoE wind damage, knockback, and three dispels.
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
        fTP            = { 3.0, 3.0, 3.0 },
        element        = xi.element.WIND,
        attackType     = xi.attackType.MAGICAL,
        damageType     = xi.damageType.WIND,
        shadowBehavior = xi.mobskills.shadowBehavior.WIPE_SHADOWS,
    }

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)
    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
        for _ = 1, 3 do
            if target:dispelStatusEffect(xi.effectFlag.DISPELABLE) == xi.effect.NONE then
                break
            end
        end
    end

    return info.damage
end

return mobskillObject
