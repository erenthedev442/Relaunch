-----------------------------------
-- Inferno Howl
-- Family: Ifrit (Player Pet)
-----------------------------------
---@type TAbilityPet
local abilityObject = {}

abilityObject.onAbilityCheck = function(player, target, ability)
    return xi.job_utils.summoner.canUseBloodPact(player, player:getPet(), target, ability)
end

abilityObject.onPetAbility = function(target, pet, petskill, summoner, action)
    xi.job_utils.summoner.onUseBloodPact(target, petskill, summoner, action)

    local skill = summoner:getSkillLevel(xi.skill.SUMMONING_MAGIC)
    local duration = 60 + utils.clamp(skill - 300, 0, 200)
    local potency = math.max(1, 20 + math.floor((skill - 300) / 10))

    target:delStatusEffect(xi.effect.ENFIRE)
    if target:addStatusEffect(xi.effect.ENFIRE, { power = potency, duration = duration, origin = pet }) then
        petskill:setMsg(xi.msg.basic.JA_GAIN_EFFECT)
    else
        petskill:setMsg(xi.msg.basic.JA_NO_EFFECT_2)
    end

    return xi.effect.ENFIRE
end

return abilityObject
