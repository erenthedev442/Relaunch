-----------------------------------
-- Howling Moon
-- Family: Avatar (Fenrir) Astral Flow — heavy AoE dark.
-- Trust Karaha-Baruha (3336): AoE dark WS; Gravitation / Compression.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

local MS_TRUST_HOWLING_MOON = 3336

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.element         = xi.element.DARK
    params.attackType      = xi.attackType.MAGICAL
    params.damageType      = xi.damageType.DARK
    params.shadowBehavior  = xi.mobskills.shadowBehavior.WIPE_SHADOWS
    params.dStatMultiplier = 1

    if skill:getID() == MS_TRUST_HOWLING_MOON then
        -- Trust chip: weapon rating + tier meleeChip feed soft bands.
        params.baseDamage = mob:getWeaponDmg()
        params.fTP        = { 2.5, 3.0, 3.75 }
    else
        params.baseDamage = mob:getMainLvl() + 2
        params.fTP        = { 9, 9, 9 }
    end

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
    end

    return info.damage
end

return mobskillObject
