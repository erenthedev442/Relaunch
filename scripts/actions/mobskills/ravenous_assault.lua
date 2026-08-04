-----------------------------------
-- Ravenous Assault
-- Trust Teodor (3635): HP Drain (no SC).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.baseDamage         = mob:getWeaponDmg()
    params.fTP                = { 2.25, 2.75, 3.5 }
    params.element            = xi.element.DARK
    params.attackType         = xi.attackType.MAGICAL
    params.damageType         = xi.damageType.DARK
    params.shadowBehavior     = xi.mobskills.shadowBehavior.IGNORE_SHADOWS
    params.skipMagicBonusDiff = true

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        skill:setMsg(xi.mobskills.mobDrainMove(mob, target, xi.mobskills.drainType.HP, info.damage, info.attackType, info.damageType))
    end

    return info.damage
end

return mobskillObject
