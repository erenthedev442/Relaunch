-----------------------------------
-- Hemocladis
-- Trust Teodor (3636): Darkness / Distortion AoE; full self heal.
-- Only while Start from Scratch aura is active (consumes aura).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

local MS_TRUST = 3636

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    if skill:getID() == MS_TRUST and mob:getLocalVar('teoAura') == 0 then
        return 1
    end

    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    params.baseDamage     = mob:getWeaponDmg()
    params.fTP            = { 3.0, 3.5, 4.25 }
    params.element        = xi.element.DARK
    params.attackType     = xi.attackType.MAGICAL
    params.damageType     = xi.damageType.DARK
    params.shadowBehavior = xi.mobskills.shadowBehavior.IGNORE_SHADOWS

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
    end

    -- Self restore + drop aura once per cast (AoE invokes this per target).
    if mob:getLocalVar('teoAura') ~= 0 then
        mob:setLocalVar('teoAura', 0)
        mob:delStatusEffect(xi.effect.COPY_IMAGE)
        mob:delStatusEffect(xi.effect.BLINK)
        mob:delStatusEffect(xi.effect.REGEN)
        xi.mobskills.mobHealMove(mob, mob:getMaxHP() - mob:getHP())
    end

    return info.damage
end

return mobskillObject
