-----------------------------------
-- Extreme Purgation
-- Family: Sandworm
-- Description: Steals all dispellable status enhancements in an area.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local stolen = 0
    while mob:stealStatusEffect(target, xi.effectFlag.DISPELABLE) ~= 0 do
        stolen = stolen + 1
    end

    if stolen > 0 then
        skill:setMsg(xi.msg.basic.EFFECT_DRAINED)
    else
        skill:setMsg(xi.msg.basic.SKILL_NO_EFFECT)
    end

    return stolen
end

return mobskillObject
