-----------------------------------
-- Salamander Flame
-- Trust: Gadalar. Magical Fire AoE. Additional effect: Dia III (30s).
-- Skillchain: Light / Fusion. Requires level 50.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    if mob:getMainLvl() < 50 then
        return 1
    end

    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    -- Signature fire AoE; B soft-band / softclamp own the ceiling.
    params.baseDamage       = mob:getWeaponDmg()
    params.fTP              = { 2.75, 3.25, 3.75 }
    params.element          = xi.element.FIRE
    params.attackType       = xi.attackType.MAGICAL
    params.damageType       = xi.damageType.FIRE
    params.shadowBehavior   = xi.mobskills.shadowBehavior.IGNORE_SHADOWS
    params.dStatMultiplier  = 1
    params.dStatAttackerMod = xi.mod.INT
    params.dStatDefenderMod = xi.mod.INT

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
        -- Dia III potency (~9/tick), 30s.
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.DIA, 9, 3, 30)
    end

    return info.damage
end

return mobskillObject
