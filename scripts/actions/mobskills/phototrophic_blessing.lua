-----------------------------------
-- Phototrophic Blessing
-- Trust Ygnas (3813) / Sinister Reign (2980):
-- AoE heal, Regen 30/tick, Defense +25%, MDB +25% for 60s.
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

local DURATION = 60

local function applyBlessing(mob, member)
    if not member:isAlive() then
        return 0
    end

    local heal = math.floor(member:getMaxHP() * 0.20 + mob:getMainLvl() * 12)
    member:addHP(heal)
    member:addStatusEffect(xi.effect.REGEN, { power = 30, duration = DURATION, tick = 3, origin = mob })
    member:addStatusEffect(xi.effect.DEFENSE_BOOST, { power = 25, duration = DURATION, origin = mob })
    member:addStatusEffect(xi.effect.MAGIC_DEF_BOOST, { power = 25, duration = DURATION, origin = mob })
    return heal
end

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local healed = 0

    if mob:getObjType() == xi.objType.TRUST then
        local master = mob:getMaster()
        if master then
            for _, member in ipairs(master:getPartyWithTrusts()) do
                if member:isAlive() and mob:checkDistance(member) <= 20 then
                    healed = math.max(healed, applyBlessing(mob, member))
                end
            end
        end
    else
        healed = applyBlessing(mob, target)
    end

    skill:setMsg(xi.msg.basic.SELF_HEAL)
    return healed
end

return mobskillObject
