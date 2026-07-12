-----------------------------------
-- Deathly Diminuendo
-- Family: Caturae (Omen)
-- AoE dark damage + Bio + Curse.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.baseDamage     = mob:getMainLvl() * 2
    params.fTP            = { 2.0, 2.0, 2.0 }
    params.element        = xi.element.DARK
    params.attackType     = xi.attackType.MAGICAL
    params.damageType     = xi.damageType.DARK
    params.shadowBehavior = xi.mobskills.shadowBehavior.WIPE_SHADOWS

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.BIO, 15, 3, 60)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.CURSE_I, 50, 0, 120)
    end

    return info.damage
end

return mobskillObject
