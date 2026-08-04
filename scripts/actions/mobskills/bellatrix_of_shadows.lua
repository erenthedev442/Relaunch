-----------------------------------
-- Bellatrix of Shadows
-- Trust Arciela (3116): Shadows stance (enfeebling + Dynastic Gravitas).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    mob:setLocalVar('ArcielaStance', 2) -- Shadows
    skill:setMsg(xi.msg.basic.NONE)
    return 0
end

return mobskillObject
