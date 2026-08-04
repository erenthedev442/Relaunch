-----------------------------------
-- Stellar Burst
-- Family: Eald'narche / Trust: Mildaurion
-- Eald'narche: AoE magical + Silence + enmity reset.
-- Mildaurion (3473): single-target magical (Darkness/Gravitation).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

local MS_MILDAURION_STELLAR = 3473

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.attackType     = xi.attackType.MAGICAL
    params.shadowBehavior = xi.mobskills.shadowBehavior.NUMSHADOWS_3

    if skill:getID() == MS_MILDAURION_STELLAR then
        -- Weapon rating so A-tier melee setDamage feeds the magical WS.
        params.baseDamage     = mob:getWeaponDmg()
        params.element        = xi.element.DARK
        params.damageType     = xi.damageType.DARK
        params.fTP            = { 4.0, 4.5, 5.0 }
        params.shadowBehavior = xi.mobskills.shadowBehavior.IGNORE_SHADOWS
    else
        params.baseDamage = mob:getMainLvl() + 2
        params.element    = xi.element.NONE
        params.damageType = xi.damageType.NONE
        params.fTP        = { 3.0, 3.0, 3.0 }
    end

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)

        if skill:getID() ~= MS_MILDAURION_STELLAR then
            xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.SILENCE, 1, 0, 30)

            if not target:isTrust() then
                mob:resetEnmity(target)
            end
        end
    end

    return info.damage
end

return mobskillObject
