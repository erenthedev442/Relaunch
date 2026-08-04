-----------------------------------
-- Envoutement
-- Family: Corse — physical damage + Curse.
-- Trust: Ullegore (3626) — dark magical damage, no Curse.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

local MS_ULLEGORE = 3626

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    -- Ullegore Trust: Magical Dark, no Curse.
    if skill:getID() == MS_ULLEGORE then
        params.baseDamage       = mob:getWeaponDmg()
        params.fTP              = { 2.5, 3.0, 3.5 }
        params.element          = xi.element.DARK
        params.attackType       = xi.attackType.MAGICAL
        params.damageType       = xi.damageType.DARK
        params.shadowBehavior   = xi.mobskills.shadowBehavior.WIPE_SHADOWS
        params.dStatMultiplier  = 1
        params.dStatAttackerMod = xi.mod.INT
        params.dStatDefenderMod = xi.mod.INT

        local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)
        if xi.mobskills.processDamage(mob, target, skill, action, info) then
            target:takeDamage(info.damage, mob, info.attackType, info.damageType)
        end

        return info.damage
    end

    -- Standard Corse: physical + Curse.
    params.baseDamage     = mob:getWeaponDmg()
    params.numHits        = 1
    params.fTP            = { 3.2, 3.2, 3.2 }
    params.attackType     = xi.attackType.PHYSICAL
    params.damageType     = xi.damageType.SLASHING
    params.shadowBehavior = xi.mobskills.shadowBehavior.NUMSHADOWS_1

    local info = xi.mobskills.mobPhysicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.CURSE_I, 25, 0, 180)
    end

    return info.damage
end

return mobskillObject
