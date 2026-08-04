-----------------------------------
-- Spine Chiller
-- Trust: Leonoyne. Conal ice magical WS. Rare short Terror.
-- Skillchain: Detonation / Induration.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.baseDamage       = mob:getWeaponDmg()
    params.fTP              = { 2.0, 2.5, 3.0 }
    params.element          = xi.element.ICE
    params.attackType       = xi.attackType.MAGICAL
    params.damageType       = xi.damageType.ICE
    params.shadowBehavior   = xi.mobskills.shadowBehavior.WIPE_SHADOWS
    params.dStatMultiplier  = 1
    params.dStatAttackerMod = xi.mod.INT
    params.dStatDefenderMod = xi.mod.INT

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)

        -- Extremely low Terror proc, short duration.
        if math.random(1, 100) <= 5 then
            xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.TERROR, 1, 0, 5)
        end
    end

    return info.damage
end

return mobskillObject
