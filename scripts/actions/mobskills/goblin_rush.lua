-----------------------------------
-- Goblin Rush
-- Family: Goblin
-- Delivers a threefold attack. Accuracy varies with TP.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.baseDamage     = mob:getWeaponDmg()
    params.numHits        = 3
    params.fTP            = { 1.0, 1.0, 1.0 }
    params.attackType     = xi.attackType.PHYSICAL
    -- Trust Fablinix is dagger; goblin mobs stay slashing.
    params.damageType     = mob:getObjType() == xi.objType.TRUST and xi.damageType.PIERCING or xi.damageType.SLASHING
    params.shadowBehavior = xi.mobskills.shadowBehavior.NUMSHADOWS_3
    params.str_wSC        = 0.3
    params.dex_wSC        = 0.3

    if mob:getObjType() == xi.objType.TRUST then
        -- Mild TP curve so CLOSER_UNTIL_TP@1500 still matters on B hybrid.
        params.fTP = { 1.0, 1.35, 1.7 }
    end

    local info = xi.mobskills.mobPhysicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
    end

    return info.damage
end

return mobskillObject
