-----------------------------------
-- Berserk-Ruf (story / BCNM Volker, skill 976)
-- Warcry effect (not Berserk). Trust Volker uses berserk_ruf.lua (3205).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    skill:setMsg(xi.mobskills.mobBuffMove(mob, xi.effect.WARCRY, 25, 0, 180))

    return xi.effect.WARCRY
end

return mobskillObject

