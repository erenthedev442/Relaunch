-----------------------------------
-- Hysteroanima
-- Used by Trust: Prishe II
-- Grants a temporary magic shield
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    -- Retail Trust: magical immunity for <5s (once per summon).
    -- UDMGMAGIC -100% produces the "resists the effects of the spell!" log.
    xi.mobskills.mobBuffMove(mob, xi.effect.MAGIC_SHIELD, 1, 0, 5)

    skill:setMsg(xi.msg.basic.USES)

    return xi.effect.MAGIC_SHIELD
end

return mobskillObject
