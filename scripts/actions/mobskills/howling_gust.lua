-----------------------------------
-- Howling Gust
-- Family: Collared Lynx (Trust: Darrcuiln)
-- Description: Wind magical damage. Fragmentation / Compression.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local params = {}

    -- Use weapon rating so S skirmisher setDamage feeds the wind WS.
    params.baseDamage     = mob:getWeaponDmg()
    params.fTP            = { 3.0, 3.5, 4.0 }
    params.element        = xi.element.WIND
    params.attackType     = xi.attackType.MAGICAL
    params.damageType     = xi.damageType.WIND
    params.shadowBehavior = xi.mobskills.shadowBehavior.IGNORE_SHADOWS

    local info = xi.mobskills.mobMagicalMove(mob, target, skill, action, params)

    if xi.mobskills.processDamage(mob, target, skill, action, info) then
        target:takeDamage(info.damage, mob, info.attackType, info.damageType)
    end

    return info.damage
end

return mobskillObject
