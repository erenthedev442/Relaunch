-----------------------------------
-- Sensual Dance
-- Family: Humanoid (Trust: Lilisette)
-- Description: AoE party Attack (+15%) and Magic Attack boost.
-- Affects party members who have Lilisette in their line of sight (gaze).
-- Does not include Lilisette herself. Boosts can wear at different times.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local mattPower = 20 + math.floor(mob:getMainLvl() / 4)
    local applied   = 0

    if mob:getObjType() == xi.objType.TRUST then
        local master = mob:getMaster()
        if master then
            for _, member in ipairs(master:getPartyWithTrusts()) do
                if
                    member:isAlive() and
                    member:getID() ~= mob:getID() and
                    mob:checkDistance(member) <= 18 and
                    member:isFacing(mob)
                then
                    member:addStatusEffect(xi.effect.ATTACK_BOOST, { power = 15, duration = 50, origin = mob })
                    member:addStatusEffect(xi.effect.MAGIC_ATK_BOOST, { power = mattPower, duration = 55, origin = mob })
                    applied = applied + 1
                end
            end
        end
    else
        if target:isAlive() and target:isFacing(mob) then
            target:addStatusEffect(xi.effect.ATTACK_BOOST, { power = 15, duration = 50, origin = mob })
            target:addStatusEffect(xi.effect.MAGIC_ATK_BOOST, { power = mattPower, duration = 55, origin = mob })
            applied = 1
        end
    end

    if applied > 0 then
        skill:setMsg(xi.msg.basic.SKILL_GAIN_EFFECT)
    else
        skill:setMsg(xi.msg.basic.SKILL_NO_EFFECT)
    end

    return xi.effect.ATTACK_BOOST
end

return mobskillObject
