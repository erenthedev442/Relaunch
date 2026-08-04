-----------------------------------
-- Bellatrix of Light
-- Trust Arciela (3115): Light stance (enhancing + Illustrious Aid).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    mob:setLocalVar('ArcielaStance', 1) -- Light
    skill:setMsg(xi.msg.basic.NONE)
    return 0
end

return mobskillObject
