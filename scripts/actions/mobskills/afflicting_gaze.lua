-----------------------------------
-- Afflicting Gaze
-- Family: Caturae (Omen)
-- Gaze attack: Curse.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local typeEffect = xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.CURSE_I, 33, 0, 120)

    if typeEffect == nil then
        typeEffect = xi.msg.basic.SKILL_NO_EFFECT
    end

    skill:setMsg(typeEffect)

    return xi.effect.CURSE_I
end

return mobskillObject
