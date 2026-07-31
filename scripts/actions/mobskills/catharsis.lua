-----------------------------------
-- Catharsis
-- Description: Restores HP. (5% of max HP)
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    skill:setMsg(xi.msg.basic.SELF_HEAL)
    return xi.mobskills.mobHealMove(mob, math.floor(mob:getMaxHP() * 0.05))
end

return mobskillObject
