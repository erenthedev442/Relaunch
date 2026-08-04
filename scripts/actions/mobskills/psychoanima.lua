-----------------------------------
-- Psychoanima
-- Used by Trust: Prishe II
-- Grants a temporary physical shield
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    -- Retail Trust: physical immunity for <5s (once per summon).
    xi.mobskills.mobBuffMove(mob, xi.effect.PHYSICAL_SHIELD, 1, 0, 5)

    skill:setMsg(xi.msg.basic.USES)

    return xi.effect.PHYSICAL_SHIELD
end

return mobskillObject
