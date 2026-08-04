-----------------------------------
-- Rousing Samba
-- Family: Humanoid (Trust: Lilisette)
-- Description: AoE party Critical Hit Rate +10%.
-- Not a real samba (no samba animation on attacks).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    if mob:getObjType() == xi.objType.TRUST then
        local master = mob:getMaster()
        if master then
            for _, member in ipairs(master:getPartyWithTrusts()) do
                if member:isAlive() and mob:checkDistance(member) <= 18 then
                    -- Blood Rage: power = CRITHITRATE (no samba animation).
                    member:addStatusEffect(xi.effect.BLOOD_RAGE, { power = 10, duration = 120, origin = mob })
                end
            end
        end

        skill:setMsg(xi.msg.basic.SKILL_GAIN_EFFECT)
        return xi.effect.BLOOD_RAGE
    end

    skill:setMsg(xi.mobskills.mobBuffMove(target, xi.effect.BLOOD_RAGE, 10, 0, 120))
    return xi.effect.BLOOD_RAGE
end

return mobskillObject
