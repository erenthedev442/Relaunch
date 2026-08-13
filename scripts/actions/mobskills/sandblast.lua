-----------------------------------
-- Jug Antlion: Sandblast
-- Pet-skill spelling differs from the monster version (sand_blast).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    skill:setMsg(xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.BLINDNESS, 40, 0, 180))
    return xi.effect.BLINDNESS
end

return mobskillObject
