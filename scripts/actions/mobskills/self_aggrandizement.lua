-----------------------------------
-- Self-Aggrandizement
-- Family: Humanoid (Trust: Ingrid II)
-- Description: Recovers HP and removes one status ailment for the entire party.
-- Recast handled by trust AI (~30s). Not a TP weaponskill.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

local function applySelfAggrandizement(member, healAmount)
    if not member:isAlive() then
        return
    end

    member:addHP(healAmount)
    member:eraseStatusEffect()
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local healAmount = math.floor(mob:getMaxHP() * 0.18 + mob:getMainLvl() * 14)

    if mob:getObjType() == xi.objType.TRUST then
        local master = mob:getMaster()
        if master then
            for _, member in ipairs(master:getPartyWithTrusts()) do
                if member:isAlive() and mob:checkDistance(member) <= 20 then
                    applySelfAggrandizement(member, healAmount)
                end
            end
        end

        skill:setMsg(xi.msg.basic.SELF_HEAL)
        return healAmount
    end

    applySelfAggrandizement(target, healAmount)
    skill:setMsg(xi.msg.basic.SELF_HEAL)
    return healAmount
end

return mobskillObject
