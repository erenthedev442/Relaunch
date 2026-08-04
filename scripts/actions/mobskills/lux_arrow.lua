-----------------------------------
-- Lux Arrow
-- Trust: Semih Lafihna. Magical Light. Additional effect: Defense Down.
-- Skillchain: Fragmentation / Distortion (closes T3 / double T3).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}
    local rangedDmg = mob:getRangedDmg()

    -- Utility closer — Sidewinder remains the damage WS.
    params.baseDamage       = (rangedDmg > 0) and rangedDmg or mob:getWeaponDmg()
    params.fTP              = { 2.0, 2.25, 2.5 }
    params.element          = xi.element.LIGHT
    params.attackType       = xi.attackType.MAGICAL
    params.damageType       = xi.damageType.LIGHT
    params.shadowBehavior   = xi.mobskills.shadowBehavior.IGNORE_SHADOWS
    params.dStatMultiplier  = 1
    params.dStatAttackerMod = xi.mod.INT
    params.dStatDefenderMod = xi.mod.INT

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.DEFENSE_DOWN, 25, 0, 60)
    end

    return info.damage
end

return mobskillObject
