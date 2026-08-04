-----------------------------------
-- Thorn Dance (Thorned Stance)
-- Family: Humanoid (Trust: Lilisette)
-- Description: Self Defense Bonus. Used when holding top enmity.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local power = 25 + math.floor(mob:getMainLvl() / 5)
    skill:setMsg(xi.mobskills.mobBuffMove(mob, xi.effect.DEFENSE_BOOST, power, 0, 180))
    return xi.effect.DEFENSE_BOOST
end

return mobskillObject
