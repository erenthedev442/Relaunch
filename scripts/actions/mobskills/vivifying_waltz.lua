-----------------------------------
-- Vivifying Waltz
-- Family: Humanoid (Trust: Lilisette)
-- Description: Party heal (Divine Waltz II–like). Amount scales with TP.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

local function waltzHeal(mob, tp)
    -- Divine Waltz II basis: (VIT+CHR)*0.75 + 270, scaled by TP spent.
    local base   = (mob:getStat(xi.mod.VIT) + mob:getStat(xi.mod.CHR)) * 0.75 + 270
    local tpMult = 1.0 + (utils.clamp(tp, 1000, 3000) - 1000) / 2000 -- 1.0@1000 → 2.0@3000
    return math.floor(base * tpMult)
end

local function applyHeal(member, amount)
    if not member:isAlive() then
        return 0
    end

    local healed = math.min(amount, member:getMaxHP() - member:getHP())
    if healed > 0 then
        member:restoreHP(healed)
        member:wakeUp()
    end

    return healed
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local heal = waltzHeal(mob, skill:getTP())
    local total = 0

    if mob:getObjType() == xi.objType.TRUST then
        local master = mob:getMaster()
        if master then
            for _, member in ipairs(master:getPartyWithTrusts()) do
                if member:isAlive() and mob:checkDistance(member) <= 18 then
                    total = total + applyHeal(member, heal)
                end
            end
        end
    else
        total = applyHeal(target, heal)
    end

    skill:setMsg(xi.msg.basic.SELF_HEAL)
    return total > 0 and total or heal
end

return mobskillObject
