-----------------------------------
-- Rejuvenation
-- Empyreal Paradox Selh'teus (1509): full self HP/MP/TP restore.
-- Trust Selh'teus (3622): party HP/MP/TP restore (script-gated).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

local MS_TRUST_REJUV = 3622

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    -- Trust AI sets selhRejuv=1 before calling; keep off the auto WS picker.
    if skill:getID() == MS_TRUST_REJUV and mob:getLocalVar('selhRejuv') == 0 then
        return 1
    end

    return 0
end

local function restoreMember(member)
    if not member:isAlive() then
        return 0
    end

    local hp = member:getMaxHP() - member:getHP()
    member:addHP(hp)
    member:addMP(member:getMaxMP() - member:getMP())
    member:addTP(3000 - member:getTP())
    return hp
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    if skill:getID() == MS_TRUST_REJUV then
        mob:setLocalVar('selhRejuv', 0)
        local healed = 0
        local master = mob:getMaster()
        if master then
            for _, member in ipairs(master:getPartyWithTrusts()) do
                if member:isAlive() and mob:checkDistance(member) <= 20 then
                    healed = math.max(healed, restoreMember(member))
                end
            end
        end

        skill:setMsg(xi.msg.basic.SELF_HEAL)
        return healed
    end

    local hp = restoreMember(target)
    skill:setMsg(xi.msg.basic.SELF_HEAL)
    return hp
end

return mobskillObject
