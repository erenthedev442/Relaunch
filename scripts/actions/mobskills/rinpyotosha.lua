-----------------------------------
-- Rinpyotosha
--
-- Description: Grants the effect of Warcry to user and any linked allies.
-- Trust: Gessho — party Attack Boost +25% for 3 minutes (5 minute cooldown in gambit).
-- Type: Enhancing
-- Utsusemi/Blink absorb: N/A
-- Range: Self and nearby allies up to ~20'.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    -- Trust: buff the master's party (players + trusts) in range.
    if mob:getObjType() == xi.objType.TRUST then
        local master = mob:getMaster()
        if master then
            for _, member in ipairs(master:getPartyWithTrusts()) do
                if member:isAlive() and mob:checkDistance(member) <= 20 then
                    xi.mobskills.mobBuffMove(member, xi.effect.WARCRY, 25, 0, 180)
                end
            end
        end

        skill:setMsg(xi.msg.basic.SKILL_GAIN_EFFECT)
        return xi.effect.WARCRY
    end

    skill:setMsg(xi.mobskills.mobBuffMove(target, xi.effect.WARCRY, 25, 0, 180))

    return xi.effect.WARCRY
end

return mobskillObject
