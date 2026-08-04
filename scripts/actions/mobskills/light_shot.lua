-----------------------------------
-- Light Shot
-- Qultada: enhance Dia (never used purely for damage).
-----------------------------------
---@type TMobSkill
local mobskillObject = {}

mobskillObject.onMobSkillCheck = function(target, mob, skill)
    return 0
end

mobskillObject.onMobWeaponSkill = function(mob, target, skill, action)
    local dia = target:getStatusEffect(xi.effect.DIA)
    if dia then
        local duration = dia:getDuration()
        local startTime = dia:getStartTime()
        local tick = dia:getTick()
        local power = math.floor(dia:getPower() * 1.5)
        local subpower = math.floor(dia:getSubPower() * 1.5)
        local tier = dia:getTier()
        local subId = dia:getSubType()

        target:delStatusEffectSilent(xi.effect.DIA)
        target:addStatusEffect(xi.effect.DIA, {
            power = power,
            duration = duration,
            origin = mob,
            tick = tick,
            subType = subId,
            subPower = subpower,
            tier = tier,
        })

        local newEffect = target:getStatusEffect(xi.effect.DIA)
        if newEffect then
            newEffect:setStartTime(startTime)
        end

        skill:setMsg(xi.msg.basic.JA_ENFEEB_IS)
        return xi.effect.DIA
    end

    skill:setMsg(xi.msg.basic.SKILL_NO_EFFECT)
    return 0
end

return mobskillObject
