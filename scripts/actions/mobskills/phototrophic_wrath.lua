-----------------------------------
-- Phototrophic Wrath
-- Trust Ygnas (3814) / Sinister Reign (2981):
-- AoE Haste II, Attack +25%, MAB +25%, Enlight (23) for 60s.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

local DURATION = 60
-- ~Haste II (307/1024) in mobskill haste units.
local HASTE_II = 3070

local function applyWrath(mob, member)
    if not member:isAlive() then
        return
    end

    member:addStatusEffect(xi.effect.HASTE, { power = HASTE_II, duration = DURATION, origin = mob })
    member:addStatusEffect(xi.effect.ATTACK_BOOST, { power = 25, duration = DURATION, origin = mob })
    member:addStatusEffect(xi.effect.MAGIC_ATK_BOOST, { power = 25, duration = DURATION, origin = mob })
    member:addStatusEffect(xi.effect.ENLIGHT, { power = 23, duration = DURATION, origin = mob })
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
                    applyWrath(mob, member)
                end
            end
        end
    else
        applyWrath(mob, target)
    end

    skill:setMsg(xi.msg.basic.SKILL_GAIN_EFFECT)
    return xi.effect.HASTE
end

return mobskillObject
