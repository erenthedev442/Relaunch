-----------------------------------
-- Predatory Glare
-- Family: Tiger
-- Description: Gaze attack that stuns targets in a fan-shaped area.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local duration = math.min(15, xi.mobskills.calculateDuration(skill:getTP(), 5, 15))

    skill:setMsg(xi.mobskills.mobGazeMove(mob, target, xi.effect.STUN, 1, 0, duration))
    return xi.effect.STUN
end

return mobskillObject
