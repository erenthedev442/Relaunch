-----------------------------------
-- Deal Out
-- Family: Cardian
-- Description: Damages enemies in an area of effect.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    -- Trust King of Hearts: prefer Shuffle when a dispelable buff is up.
    if mob:isTrust() then
        if target:hasStatusEffectByFlag(xi.effectFlag.DISPELABLE) then
            return 1
        end

        return 0
    end

    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.baseDamage     = mob:getWeaponDmg()
    params.numHits        = 1
    params.fTP            = { 2.0, 2.0, 2.0 }
    params.attackType     = xi.attackType.PHYSICAL
    params.damageType     = xi.damageType.SLASHING
    params.shadowBehavior = xi.mobskills.shadowBehavior.NUMSHADOWS_3 -- TODO: Capture shadowBehavior

    local info = xi.mobskills.mobPhysicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)

        if mob:isMobType(xi.mobType.NOTORIOUS) then
            mob:resetEnmity(target)
        end
    end

    return info.damage
end

return mobskillObject
