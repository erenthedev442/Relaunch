-----------------------------------
-- Shared Arciela light magical auto-attack (MAB/MDB path).
-----------------------------------
local arcielaAA = {}

arcielaAA.onMobSkillCheck = function(target, mob, skill)
    return 0
end

arcielaAA.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    -- Light AA; support/mage package MATT + MAGIC_DAMAGE carry the tier curve.
    params.baseDamage     = mob:getMainLvl() + 2
    params.fTP            = { 1.0, 1.0, 1.0 }
    params.element        = xi.element.LIGHT
    params.attackType     = xi.attackType.MAGICAL
    params.damageType     = xi.damageType.LIGHT
    params.shadowBehavior = xi.mobskills.shadowBehavior.IGNORE_SHADOWS
    params.primaryMessage = xi.msg.basic.HIT_DMG

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
    end

    return info.damage
end

return arcielaAA
