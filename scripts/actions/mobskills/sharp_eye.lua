-----------------------------------
-- Sharp Eye
-- Family: Qiqirn (Trust: Chacharoon)
-- Description: Conal. Gravity II (Weight) + 25% Defense Down. No damage.
-- Notes: Looks like a gaze but has no facing requirement.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    -- Gravity II → WEIGHT (wind). Defense Down also wind; half-resist halves duration via resistRate.
    local gravity = xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.WEIGHT, 50, 0, 60)
    local defDown = xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.DEFENSE_DOWN, 25, 0, 45)

    -- Defense Down shows in the log when Gravity is fully resisted.
    if gravity == xi.msg.basic.SKILL_ENFEEB_IS then
        skill:setMsg(xi.msg.basic.SKILL_ENFEEB_IS)
        return xi.effect.WEIGHT
    elseif defDown == xi.msg.basic.SKILL_ENFEEB_IS then
        skill:setMsg(xi.msg.basic.SKILL_ENFEEB_IS)
        return xi.effect.DEFENSE_DOWN
    end

    skill:setMsg(xi.msg.basic.SKILL_MISS)
    return 0
end

return mobskillObject
