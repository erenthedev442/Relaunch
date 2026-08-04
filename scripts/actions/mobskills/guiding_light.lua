-----------------------------------
-- Guiding Light
-- Trust Arciela (3453): Party Atk/Def/MAB/MDB up for 30s.
-- Usable from either Bellatrix stance. Overwrites Cocoon / Saline Coat style
-- DEF / MDB boosts via stronger application.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

local DURATION = 30
local POWER = 25

local function applyGuidingLight(mob, member)
    if not member:isAlive() then
        return
    end

    -- Strip weaker DEF/MDB coats so Guiding Light takes the slot.
    member:delStatusEffect(xi.effect.DEFENSE_BOOST)
    member:delStatusEffect(xi.effect.MAGIC_DEF_BOOST)

    member:addStatusEffect(xi.effect.ATTACK_BOOST, { power = POWER, duration = DURATION, origin = mob })
    member:addStatusEffect(xi.effect.DEFENSE_BOOST, { power = POWER, duration = DURATION, origin = mob })
    member:addStatusEffect(xi.effect.MAGIC_ATK_BOOST, { power = POWER, duration = DURATION, origin = mob })
    member:addStatusEffect(xi.effect.MAGIC_DEF_BOOST, { power = POWER, duration = DURATION, origin = mob })
end

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    if mob:getObjType() == xi.objType.TRUST then
        local master = mob:getMaster()
        if master then
            for _, member in ipairs(master:getPartyWithTrusts()) do
                if member:isAlive() and mob:checkDistance(member) <= 20 then
                    applyGuidingLight(mob, member)
                end
            end
        end
    else
        applyGuidingLight(mob, target)
    end

    skill:setMsg(xi.msg.basic.SKILL_GAIN_EFFECT)
    return xi.effect.ATTACK_BOOST
end

return mobskillObject
