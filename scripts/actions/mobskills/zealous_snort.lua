-----------------------------------
-- Zealous Snort
-- Family: Raaz
-- Description: Attack boost for pet and master.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local power = 25
    local duration = 120

    skill:setMsg(xi.mobskills.mobBuffMove(mob, xi.effect.ATTACK_BOOST, power, 0, duration))

    local master = mob:getMaster()
    if master and master:isAlive() then
        master:addStatusEffect(xi.effect.ATTACK_BOOST, power, 0, duration)
    end

    return xi.effect.ATTACK_BOOST
end

return mobskillObject
