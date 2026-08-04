-----------------------------------
-- Salvation Scythe
-- Trust: Domina Shantotto. Magical Dark AoE.
-- Additional effect: Poison, Bio, Paralysis, Slow.
-- Skillchain: Light (closes with Shantotto Divine Malison setups).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.baseDamage       = mob:getWeaponDmg()
    params.fTP              = { 2.75, 3.25, 3.75 }
    params.element          = xi.element.DARK
    params.attackType       = xi.attackType.MAGICAL
    params.damageType       = xi.damageType.DARK
    params.shadowBehavior   = xi.mobskills.shadowBehavior.IGNORE_SHADOWS
    params.dStatMultiplier  = 1
    params.dStatAttackerMod = xi.mod.INT
    params.dStatDefenderMod = xi.mod.INT

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)

        local lvl = mob:getMainLvl()
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.POISON, math.max(1, math.floor(lvl / 5)), 3, 60)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.BIO, math.max(1, math.floor(lvl / 6)), 3, 60)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.PARALYSIS, 20, 0, 60)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.SLOW, 2000, 0, 60)
    end

    return info.damage
end

return mobskillObject
