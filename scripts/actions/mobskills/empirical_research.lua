-----------------------------------
-- Empirical Research
-- Trust: Shantotto II. Magical damage + Magic Defense Down (25).
-- Skillchain: Fragmentation / Transfixion.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.baseDamage       = mob:getWeaponDmg()
    params.fTP              = { 2.5, 3.0, 3.5 }
    params.element          = xi.element.NONE
    params.attackType       = xi.attackType.MAGICAL
    params.damageType       = xi.damageType.ELEMENTAL
    params.shadowBehavior   = xi.mobskills.shadowBehavior.WIPE_SHADOWS
    params.dStatMultiplier  = 1
    params.dStatAttackerMod = xi.mod.INT
    params.dStatDefenderMod = xi.mod.INT

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.MAGIC_DEF_DOWN, 25, 0, 60)
    end

    return info.damage
end

return mobskillObject
