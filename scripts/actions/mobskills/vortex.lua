-----------------------------------
-- Vortex
-- Family: Eald'narche / Trust: Mildaurion
-- Eald'narche: physical AoE + Terror/Bind.
-- Mildaurion (3472): magical wind damage (Distortion/Reverberation).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

local MS_MILDAURION_VORTEX = 3472

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    -- Trust Mildaurion: Magical Wind (retail kit). Weapon rating feeds A-tier setDamage.
    if skill:getID() == MS_MILDAURION_VORTEX then
        params.baseDamage     = mob:getWeaponDmg()
        params.fTP            = { 3.5, 4.0, 4.5 }
        params.element        = xi.element.WIND
        params.attackType     = xi.attackType.MAGICAL
        params.damageType     = xi.damageType.WIND
        params.shadowBehavior = xi.mobskills.shadowBehavior.IGNORE_SHADOWS

        local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)

        if xi.mobskills.processDamage(mob, target, skill, action, info) then
            target:takeDamage(info.damage, mob, info.attackType, info.damageType)
        end

        return info.damage
    end

    -- Eald'narche / other: physical vortex.
    params.baseDamage     = mob:getWeaponDmg()
    params.numHits        = 1
    params.fTP            = { 1.5, 1.5, 1.5 }
    params.attackType     = xi.attackType.PHYSICAL
    params.damageType     = xi.damageType.SLASHING
    params.shadowBehavior = xi.mobskills.shadowBehavior.NUMSHADOWS_3

    local info = xi.mobskills.mobPhysicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)

        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.TERROR, 1, 0, 9)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.BIND, 1, 0, 30)

        mob:resetEnmity(target)
    end

    return info.damage
end

return mobskillObject
