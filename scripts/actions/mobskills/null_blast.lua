-----------------------------------
-- Null Blast
-- Trust: Robel-Akbel. Magical dark WS; damage dealt → MP.
-- Additional effect: Magic Evasion Down. Skillchain: Gravitation.
-- Usable at range.
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
        mob:addMP(info.damage)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.MAGIC_EVASION_DOWN, 10, 0, 60)
    end

    return info.damage
end

return mobskillObject
