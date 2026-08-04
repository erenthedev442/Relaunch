-----------------------------------
-- Inspirit
-- Family: Humanoid (Trust: Lehko Habhoka)
-- Description: AoE restore HP + MP and Erase one status. No skillchain.
-- Opportunistic TP move (not gated on party HP).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

local function applyInspirit(member, healHP, healMP)
    if not member:isAlive() then
        return
    end

    member:addHP(healHP)
    member:addMP(healMP)
    member:eraseStatusEffect()
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local healHP = math.floor(mob:getMaxHP() * 0.15 + mob:getMainLvl() * 10)
    local healMP = math.floor(mob:getMaxMP() * 0.10 + mob:getMainLvl() * 4)

    if mob:getObjType() == xi.objType.TRUST then
        local master = mob:getMaster()
        if master then
            for _, member in ipairs(master:getPartyWithTrusts()) do
                if member:isAlive() and mob:checkDistance(member) <= 20 then
                    applyInspirit(member, healHP, healMP)
                end
            end
        end

        skill:setMsg(xi.msg.basic.SELF_HEAL)
        return healHP
    end

    applyInspirit(target, healHP, healMP)
    skill:setMsg(xi.msg.basic.SELF_HEAL)
    return healHP
end

return mobskillObject
