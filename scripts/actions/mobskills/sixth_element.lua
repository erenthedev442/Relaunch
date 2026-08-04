-----------------------------------
-- Sixth Element
-- Trust: Ovjang. Non-elemental magical damage. Skillchain: Gravitation.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    -- Signature Stormwaker nuke; C soft-band / softclamp own the ceiling.
    params.baseDamage       = mob:getWeaponDmg()
    params.fTP              = { 2.5, 3.0, 3.5 }
    params.element          = xi.element.NONE
    params.attackType       = xi.attackType.MAGICAL
    params.damageType       = xi.damageType.NONE
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

return mobskillObject
