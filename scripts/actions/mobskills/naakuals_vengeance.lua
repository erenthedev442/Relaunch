-----------------------------------
-- Naakual's Vengeance (Arciela II)
-- Low-HP recovery: full self HP/MP + AoE Light damage.
-- Light / Fusion. 5-minute script CD (not on TP skill list).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    mob:addHP(mob:getMaxHP() - mob:getHP())
    mob:addMP(mob:getMaxMP() - mob:getMP())

    if math.random(1, 100) <= 50 then
        xi.trust.message(mob, xi.trust.messageOffset.SPECIAL_MOVE_1)
    end

    local params = {}
    params.baseDamage     = mob:getWeaponDmg()
    params.fTP            = { 4.0, 4.5, 5.25 }
    params.element        = xi.element.LIGHT
    params.attackType     = xi.attackType.MAGICAL
    params.damageType     = xi.damageType.LIGHT
    params.shadowBehavior = xi.mobskills.shadowBehavior.WIPE_SHADOWS
    params.mnd_wSC        = 0.3
    params.int_wSC        = 0.3

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
    end

    return info.damage
end

return mobskillObject
