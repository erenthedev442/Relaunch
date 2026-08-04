-----------------------------------
-- Petal Pirouette
-- Description: Whirling petals reduce TP to zero (AoE).
-- Notes: Full reset on normal foes; reduced on NMs (remaining TP shown in log).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local newTP = 0

    if target:isNM() then
        -- Reduced NM effect: strip half of current TP; log shows what remains.
        newTP = math.floor(target:getTP() * 0.5)
    end

    target:setTP(newTP)
    skill:setMsg(xi.msg.basic.TP_REDUCED)

    return newTP
end

return mobskillObject
