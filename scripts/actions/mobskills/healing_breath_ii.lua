-----------------------------------
-- Healing Breath II
-- Family: Wyvern
-- Description: Restores HP for target. Mid tier (scales between Healing Breath I and III).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local curePower = 40 + math.floor(mob:getMaxHP() * 42 / 256)

    skill:setMsg(xi.msg.basic.SELF_HEAL)

    return xi.mobskills.mobHealMove(target, curePower)
end

return mobskillObject
