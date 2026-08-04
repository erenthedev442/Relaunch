-----------------------------------
-- Tripe Gripe
-- Family: Qiqirn (Trust: Chacharoon)
-- Description: Amnesia + Attack Boost on the target. No damage.
-- Notes: Attack Boost on the enemy is intentional (Absorb-Attri / Atomos synergy).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local amnesia = xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.AMNESIA, 1, 0, 30)
    local atkBoost = xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.ATTACK_BOOST, 50, 0, 30)

    if amnesia == xi.msg.basic.SKILL_ENFEEB_IS then
        skill:setMsg(xi.msg.basic.SKILL_ENFEEB_IS)
        return xi.effect.AMNESIA
    elseif atkBoost == xi.msg.basic.SKILL_ENFEEB_IS then
        skill:setMsg(xi.msg.basic.SKILL_GAIN_EFFECT)
        return xi.effect.ATTACK_BOOST
    end

    skill:setMsg(xi.msg.basic.SKILL_MISS)
    return 0
end

return mobskillObject
