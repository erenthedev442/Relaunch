-----------------------------------
-- Nott
-- Trust club weaponskill (Apururu UC / Yoran-Oran UC / Pieuje UC / Naja UC).
-- Restores HP and MP (Dagan-like). Amount scales with TP.
-- No damage / no skillchain. Naja UC has no MP — HP restore only.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local tp = skill:getTP()
    -- ~15–35% max MP and ~10–25% max HP from 1000→3000 TP.
    local ftpmp = 0.15 + (math.min(tp, 3000) - 1000) * (0.20 / 2000)
    local ftphp = 0.10 + (math.min(tp, 3000) - 1000) * (0.15 / 2000)
    if tp < 1000 then
        ftpmp = 0.15
        ftphp = 0.10
    end

    local maxMP = mob:getMaxMP()
    local mpAmount = maxMP > 0 and math.floor(maxMP * ftpmp) or 0
    local hpAmount = math.floor(mob:getMaxHP() * ftphp)

    if mpAmount > 0 then
        mob:addMP(mpAmount)
    end

    mob:addHP(hpAmount)

    if mpAmount > 0 then
        skill:setMsg(xi.msg.basic.SKILL_RECOVERS_MP)
        return mpAmount
    end

    skill:setMsg(xi.msg.basic.SKILL_RECOVERS_HP)
    return hpAmount
end

return mobskillObject
