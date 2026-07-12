-----------------------------------
-- Stygian Sphere
-- Family: Caturae (Omen)
-- Restores the Caturae's HP and erases its status ailments.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local healAmount = math.min(2000, mob:getMaxHP() - mob:getHP())

    mob:eraseAllStatusEffect()
    xi.mobskills.mobHealMove(mob, healAmount)

    skill:setMsg(xi.msg.basic.SELF_HEAL)

    return healAmount
end

return mobskillObject
