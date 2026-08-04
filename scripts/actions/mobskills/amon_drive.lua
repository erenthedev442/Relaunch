-----------------------------------
-- Amon Drive
-- Family: Humanoid (Ark Angel TT / Trust: AATT)
-- AoE weaponskill. Additional effect: Paralysis + Petrification.
-- Trust kit lists Para+Petrify (story may also poison).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}
    local isTrust = mob:getObjType() == xi.objType.TRUST

    params.baseDamage     = mob:getWeaponDmg()
    params.numHits        = 1
    -- A-tier signature WS; soft band / softclamp own the ceiling.
    params.fTP            = isTrust and { 3.0, 3.5, 4.0 } or { 2.5, 2.5, 2.5 }
    params.attackType     = xi.attackType.PHYSICAL
    params.damageType     = xi.damageType.SLASHING
    params.shadowBehavior = xi.mobskills.shadowBehavior.NUMSHADOWS_2

    local info = xi.mobskills.mobPhysicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)

        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.PARALYSIS, 25, 0, 60)
        local petri = isTrust and 10 or (math.random(8, 15) + mob:getMainLvl() / 3)
        xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.PETRIFICATION, 1, 0, petri)

        if not isTrust then
            xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.POISON, math.ceil(mob:getMainLvl() / 5), 3, 60)
        end
    end

    return info.damage
end

return mobskillObject
