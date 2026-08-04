-----------------------------------
-- Vehement Resolution
-- Trust: Morimar ability. Consumes TP, full heal, erase debuffs, glow.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    mob:setTP(0)
    mob:delStatusEffectsByFlag(xi.effectFlag.WALTZABLE, false)
    mob:delStatusEffectsByFlag(xi.effectFlag.ERASABLE, false)

    -- Glow marker for AI (no SC close; next WS = 12 Blades @2000).
    mob:setLocalVar('moriGlow', 1)

    skill:setMsg(xi.msg.basic.SELF_HEAL)

    return xi.mobskills.mobHealMove(mob, mob:getMaxHP())
end

return mobskillObject
