-----------------------------------
-- Bubble Curtain
--
-- Description: Reduces magical damage received by 50%
-- Type: Enhancing
-- Utsusemi/Blink absorb: N/A
-- Range: Self
-- Notes:Nightmare Crabs use an enhanced version that applies a Magic Defense Boost that cannot be dispelled.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    skill:setMsg(xi.mobskills.mobBuffMove(target, xi.effect.SHELL, 5000, 0, 180))
    -- Share buff with the master when cast by a player's jug pet.
    local master = mob:getMaster()
    if master and master:isPC() then
        master:addStatusEffect(xi.effect.SHELL, 5000, 0, 180)
    end
    return xi.effect.SHELL
end

return mobskillObject
