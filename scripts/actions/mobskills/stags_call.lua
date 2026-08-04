-----------------------------------
-- Stag's Call
-- Family: Humanoid (Trust: Excenmille (S))
-- Description: AoE party Haste +15%, Attack +15%, MAB +15 for 3 minutes.
-- Attack buff does not overwrite Nature's Meditation (ATTACK_BOOST).
-- Haste uses the normal Haste effect (overwritten by Haste / Haste II).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

local function applyStagsCall(member)
    -- Haste 15% (HASTE_MAGIC is /10000). Same effect as Haste spell → can be overwritten.
    xi.mobskills.mobBuffMove(member, xi.effect.HASTE, 1500, 0, 180)
    -- MAB +15 (flat MATT).
    xi.mobskills.mobBuffMove(member, xi.effect.MAGIC_ATK_BOOST, 15, 0, 180)
    -- Attack +15%: do not overwrite Nature's Meditation / existing ATTACK_BOOST.
    if not member:hasStatusEffect(xi.effect.ATTACK_BOOST) then
        xi.mobskills.mobBuffMove(member, xi.effect.ATTACK_BOOST, 15, 0, 180)
    end
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    if mob:getObjType() == xi.objType.TRUST then
        local master = mob:getMaster()
        if master then
            for _, member in ipairs(master:getPartyWithTrusts()) do
                if member:isAlive() and mob:checkDistance(member) <= 20 then
                    applyStagsCall(member)
                end
            end
        end

        skill:setMsg(xi.msg.basic.SKILL_GAIN_EFFECT)
        return xi.effect.HASTE
    end

    applyStagsCall(target)
    skill:setMsg(xi.msg.basic.SKILL_GAIN_EFFECT)
    return xi.effect.HASTE
end

return mobskillObject
