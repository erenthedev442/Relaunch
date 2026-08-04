-----------------------------------
-- Luminous Lance
-- Empyreal Paradox Selh'teus (1508): ranged + Terror / Promathia anim.
-- Trust Selh'teus (3621): ranged physical weaponskill (no Terror).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

local MS_TRUST_LANCE = 3621

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.baseDamage     = mob:getWeaponDmg()
    params.numHits        = 1
    params.attackType     = xi.attackType.PHYSICAL
    params.damageType     = xi.damageType.PIERCING
    params.shadowBehavior = xi.mobskills.shadowBehavior.NUMSHADOWS_1
    params.skipParry      = true
    params.skipGuard      = true
    params.skipBlock      = true

    if skill:getID() == MS_TRUST_LANCE then
        params.fTP = { 3.0, 3.5, 4.25 }
    else
        params.fTP = { 3.0, 3.0, 3.0 }
    end

    local info = xi.mobskills.mobRangedMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)

        -- Empyreal Paradox only: Promathia phase / Terror.
        if skill:getID() ~= MS_TRUST_LANCE then
            target:setAnimationSub(3)
            target:addStatusEffect(xi.effect.TERROR, { duration = 30, origin = mob })
        end
    end

    return info.damage
end

return mobskillObject
