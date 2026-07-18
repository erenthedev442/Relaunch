-----------------------------------
-- Desiccation
-- Family: Sandworm
-- Description: Conal wind damage, equipment removal, recast reset, knockback.
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
        fTP            = { 1.0, 1.0, 1.0 },
        element        = xi.element.WIND,
        attackType     = xi.attackType.MAGICAL,
        damageType     = xi.damageType.WIND,
        shadowBehavior = xi.mobskills.shadowBehavior.WIPE_SHADOWS,
    }

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)
    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
        if target:isPC() then
            for slot = xi.slot.MAIN, xi.slot.BACK do
                target:unequipItem(slot)
            end
            target:resetRecasts()
        end
    end

    return info.damage
end

return mobskillObject
