-----------------------------------
-- Armor Shatterer
-- Family: Automaton (Sharpshot)
-- Description: Delivers a single ranged attack. Additional effect: strong Defense Down. Damage varies with TP.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.baseDamage       = mob:getWeaponDmg()
    params.numHits          = 1
    params.fTP              = { 3.0, 3.75, 5.0 }
    params.accuracyModifier = { 100, 100, 100 }
    params.dex_wSC          = 0.5
    params.attackType       = xi.attackType.RANGED
    params.damageType       = xi.damageType.PIERCING
    params.shadowBehavior   = xi.mobskills.shadowBehavior.NUMSHADOWS_1
    params.skipParry        = true
    params.skipGuard        = true
    params.skipBlock        = true

    local info = xi.mobskills.mobRangedMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.DEFENSE_DOWN, 40, 0, 120)
    end

    return info.damage
end

return mobskillObject
