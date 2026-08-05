-----------------------------------
-- Shared Balamor dark magical auto-attack
-----------------------------------
local balamorAA = {}

balamorAA.onMobSkillCheck = function(target, mob, skill)
    return 0
end

balamorAA.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    -- AA lane: no MAGIC_DAMAGE/MAB (nukes/absorbs keep the mage package).
    params.baseDamage         = mob:getWeaponDmg()
    params.fTP                = { 1.0, 1.0, 1.0 }
    params.element            = xi.element.DARK
    params.attackType         = xi.attackType.MAGICAL
    params.damageType         = xi.damageType.DARK
    params.shadowBehavior     = xi.mobskills.shadowBehavior.IGNORE_SHADOWS
    params.primaryMessage     = xi.msg.basic.HIT_DMG
    params.skipMagicBonusDiff = true

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
    end

    return info.damage
end

return balamorAA
