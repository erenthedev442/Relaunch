-----------------------------------
-- Nullifying Dropkick
-- Empyreal Paradox Prishe (1489): strips Physical/Magic Shields (no damage).
-- Trust Prishe / Prishe II (3234): physical H2H WS.
-- Skillchain: Induration / Detonation / Impaction.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

local MS_TRUST_NULLIFYING = 3234

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    -- CoP helper: remove Promathia's shields only.
    if skill:getID() ~= MS_TRUST_NULLIFYING then
        target:delStatusEffect(xi.effect.PHYSICAL_SHIELD)
        target:delStatusEffect(xi.effect.MAGIC_SHIELD)
        skill:setMsg(xi.msg.basic.NONE)
        return 0
    end

    local params = {}

    params.baseDamage     = mob:getWeaponDmg()
    params.numHits        = 1
    params.fTP            = { 2.5, 3.0, 3.75 }
    params.attackType     = xi.attackType.PHYSICAL
    params.damageType     = xi.damageType.HTH
    params.shadowBehavior = xi.mobskills.shadowBehavior.NUMSHADOWS_1
    params.str_wSC        = 0.4
    params.vit_wSC        = 0.4

    local info = xi.mobskills.mobPhysicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
    end

    return info.damage
end

return mobskillObject
