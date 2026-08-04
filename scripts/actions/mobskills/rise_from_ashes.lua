-----------------------------------
-- Rise From Ashes
-- Family: Humanoid (Trust: Iroha II)
-- Description: AoE restore 25% HP + MP, and Stoneskin (~500 HP).
-- Used via trust AI (not a TP weaponskill).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

local function applyRiseFromAshes(member)
    if not member:isAlive() then
        return
    end

    local healHP = math.floor(member:getMaxHP() * 0.25)
    local healMP = math.floor(member:getMaxMP() * 0.25)
    member:addHP(healHP)
    member:addMP(healMP)
    xi.mobskills.mobBuffMove(member, xi.effect.STONESKIN, 500, 0, 60)
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    if mob:getObjType() == xi.objType.TRUST then
        local master = mob:getMaster()
        if master then
            for _, member in ipairs(master:getPartyWithTrusts()) do
                if member:isAlive() and mob:checkDistance(member) <= 20 then
                    applyRiseFromAshes(member)
                end
            end
        end

        skill:setMsg(xi.msg.basic.SELF_HEAL)
        return math.floor(mob:getMaxHP() * 0.25)
    end

    applyRiseFromAshes(target)
    skill:setMsg(xi.msg.basic.SELF_HEAL)
    return math.floor(target:getMaxHP() * 0.25)
end

return mobskillObject
