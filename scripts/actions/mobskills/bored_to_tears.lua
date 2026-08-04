-----------------------------------
-- Bored to Tears
-- Trust: Ullegore. Applies a mild Slow (weaker than Slow II).
-- Flavor: target "has become noticeably bored" (trust SPECIAL_MOVE_1).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    -- Slow II-class is ~3000; Bored is intentionally milder.
    skill:setMsg(xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.SLOW, 2000, 0, 90))

    return xi.effect.SLOW
end

return mobskillObject
