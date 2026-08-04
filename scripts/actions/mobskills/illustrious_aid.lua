-----------------------------------
-- Illustrious Aid
-- Trust Arciela (3452): AoE party heal. Light stance; used when multiple
-- party members are in yellow HP (<75%).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

local MS_TRUST = 3452
local STANCE_LIGHT = 1

local function yellowCount(mob)
    local master = mob:getMaster()
    if not master then
        return 0
    end

    local count = 0
    for _, member in ipairs(master:getPartyWithTrusts()) do
        if member:isAlive() and member:getHPP() < 75 and mob:checkDistance(member) <= 20 then
            count = count + 1
        end
    end

    return count
end

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    if skill:getID() ~= MS_TRUST then
        return 0
    end

    if mob:getLocalVar('ArcielaStance') ~= STANCE_LIGHT then
        return 1
    end

    if yellowCount(mob) < 2 then
        return 1
    end

    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local heal = math.floor(mob:getMainLvl() * 8 + 50) -- ~842 at 99
    local healed = 0

    if mob:getObjType() == xi.objType.TRUST then
        local master = mob:getMaster()
        if master then
            for _, member in ipairs(master:getPartyWithTrusts()) do
                if member:isAlive() and mob:checkDistance(member) <= 20 then
                    member:addHP(heal)
                    healed = math.max(healed, heal)
                end
            end
        end
    else
        target:addHP(heal)
        healed = heal
    end

    skill:setMsg(xi.msg.basic.SELF_HEAL)
    return healed
end

return mobskillObject
