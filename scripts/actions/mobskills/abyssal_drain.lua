-----------------------------------
-- Abyssal Drain
-- Family: Humanoid (Zeid / Trust: Zeid)
-- Description: Dark damage. Additional effect: HP Drain.
-- No skillchain properties.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}
    local isTrust = mob:getObjType() == xi.objType.TRUST

    -- Trust A-tier: weapon rating feeds power path. Story Zeid keeps level-based.
    params.baseDamage         = isTrust and mob:getWeaponDmg() or (mob:getMainLvl() + 2)
    params.fTP                = isTrust and { 2.5, 2.75, 3.0 } or { 2.0, 2.0, 2.0 }
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
