-----------------------------------
-- Mighty Guard
-- Family: Shinryu
-- Description: Grants defensive buffs to the user.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    mob:addStatusEffect(xi.effect.MIGHTY_GUARD, 1, 0, 180)
    mob:addStatusEffect(xi.effect.PROTECT, 350, 0, 180)
    mob:addStatusEffect(xi.effect.SHELL, 350, 0, 180)
    mob:addStatusEffect(xi.effect.HASTE, 1500, 0, 180)

    skill:setMsg(xi.msg.basic.SKILL_GAIN_EFFECT)
    return xi.effect.MIGHTY_GUARD
end

return mobskillObject
