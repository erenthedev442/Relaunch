-----------------------------------
-- Heavenward Howl
-- Family: Fenrir (Player Pet)
-----------------------------------
---@type TAbilityPet
local abilityObject = {}

abilityObject.onAbilityCheck = function(player, target, ability)
    return xi.job_utils.summoner.canUseBloodPact(player, player:getPet(), target, ability)
end

abilityObject.onPetAbility = function(target, pet, petskill, summoner, action)
    xi.job_utils.summoner.onUseBloodPact(target, petskill, summoner, action)

    local bonusTime = utils.clamp(summoner:getSkillLevel(xi.skill.SUMMONING_MAGIC) - 300, 0, 200)
    local duration = 60 + bonusTime
    local moonCycle = getVanadielMoonCycle()
    local effect = xi.effect.ENDRAIN
    local potencyByCycle =
    {
        [xi.moonCycle.NEW_MOON]                = 5,
        [xi.moonCycle.LESSER_WAXING_CRESCENT]  = 4,
        [xi.moonCycle.GREATER_WAXING_CRESCENT] = 2,
        [xi.moonCycle.FIRST_QUARTER]           = 5,
        [xi.moonCycle.LESSER_WAXING_GIBBOUS]   = 8,
        [xi.moonCycle.GREATER_WAXING_GIBBOUS]  = 12,
        [xi.moonCycle.FULL_MOON]               = 15,
        [xi.moonCycle.GREATER_WANING_GIBBOUS]  = 12,
        [xi.moonCycle.LESSER_WANING_GIBBOUS]   = 8,
        [xi.moonCycle.THIRD_QUARTER]            = 1,
        [xi.moonCycle.GREATER_WANING_CRESCENT] = 2,
        [xi.moonCycle.LESSER_WANING_CRESCENT]  = 4,
    }

    if
        moonCycle == xi.moonCycle.NEW_MOON or
        moonCycle == xi.moonCycle.LESSER_WAXING_CRESCENT or
        moonCycle == xi.moonCycle.GREATER_WAXING_CRESCENT or
        moonCycle == xi.moonCycle.THIRD_QUARTER or
        moonCycle == xi.moonCycle.GREATER_WANING_CRESCENT or
        moonCycle == xi.moonCycle.LESSER_WANING_CRESCENT
    then
        effect = xi.effect.ENASPIR
    end

    target:delStatusEffect(xi.effect.ENDRAIN)
    target:delStatusEffect(xi.effect.ENASPIR)

    if target:addStatusEffect(effect, { power = potencyByCycle[moonCycle], duration = duration, origin = pet }) then
        petskill:setMsg(xi.msg.basic.JA_GAIN_EFFECT)
    else
        petskill:setMsg(xi.msg.basic.JA_NO_EFFECT_2)
    end

    return effect
end

return abilityObject
