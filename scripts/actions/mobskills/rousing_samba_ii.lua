-----------------------------------
-- Rousing Samba II
-- Family: Humanoid (Trust: Lilisette II)
-- Description: JA-style samba (script spends 350 TP). AoE Crit Rate +10%;
-- Lilisette herself receives Crit Rate +75%.
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
                    local power = (member:getID() == mob:getID()) and 75 or 10
                    if member:hasStatusEffect(xi.effect.BLOOD_RAGE) then
                        member:delStatusEffect(xi.effect.BLOOD_RAGE)
                    end

                    member:addStatusEffect(xi.effect.BLOOD_RAGE, { power = power, duration = 90, origin = mob })
                end
            end
        end

        skill:setMsg(xi.msg.basic.SKILL_GAIN_EFFECT)
        return xi.effect.BLOOD_RAGE
    end

    skill:setMsg(xi.mobskills.mobBuffMove(target, xi.effect.BLOOD_RAGE, 10, 0, 90))
    return xi.effect.BLOOD_RAGE
end

return mobskillObject
