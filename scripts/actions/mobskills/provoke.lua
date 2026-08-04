-----------------------------------
-- Provoke
-- Trust Mnejing: Strobe / Strobe II (higher VE from 80+).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local volEnmity = 1800 -- Strobe I

    if
        mob:isTrust() and
        mob:getTrustID() == xi.magic.spell.MNEJING and
        mob:getMainLvl() >= 80
    then
        volEnmity = 2400 -- Strobe II
    end

    target:addEnmity(mob, 1, volEnmity)
    skill:setMsg(xi.msg.basic.NONE)
end

return mobskillObject
