-----------------------------------
-- Diamond Storm
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
    local result = xi.mobskills.mobStatusEffectMove(
        pet, target, xi.effect.EVASION_DOWN, 25, 0, 180 + bonusTime)

    petskill:setMsg(result)
    return xi.effect.EVASION_DOWN
end

return abilityObject
