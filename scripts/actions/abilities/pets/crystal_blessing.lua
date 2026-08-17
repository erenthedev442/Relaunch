-----------------------------------
-- Crystal Blessing
-- Family: Shiva (Player Pet)
-----------------------------------
---@type TAbilityPet
local abilityObject = {}

abilityObject.onAbilityCheck = function(player, target, ability)
    return xi.job_utils.summoner.canUseBloodPact(player, player:getPet(), target, ability)
end

abilityObject.onPetAbility = function(target, pet, petskill, summoner, action)
    xi.job_utils.summoner.onUseBloodPact(target, petskill, summoner, action)

    local bonusTime = utils.clamp(summoner:getSkillLevel(xi.skill.SUMMONING_MAGIC) - 300, 0, 200)
    local duration = 180 + bonusTime

    target:delStatusEffect(xi.effect.TP_BONUS)
    if target:addStatusEffect(xi.effect.TP_BONUS, { power = 250, subPower = 250, duration = duration, origin = pet }) then
        petskill:setMsg(xi.msg.basic.JA_GAIN_EFFECT)
    else
        petskill:setMsg(xi.msg.basic.JA_NO_EFFECT_2)
    end

    return xi.effect.TP_BONUS
end

return abilityObject
