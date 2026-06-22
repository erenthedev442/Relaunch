-----------------------------------
-- Healing Breath I
-- Family: Wyvern
-- Description: Restores HP for target. Lowest tier (scales below Healing Breath II/III).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local curePower = 20 + math.floor(mob:getMaxHP() * 21 / 256)

    skill:setMsg(xi.msg.basic.SELF_HEAL)

    return xi.mobskills.mobHealMove(target, curePower)
end

return mobskillObject
