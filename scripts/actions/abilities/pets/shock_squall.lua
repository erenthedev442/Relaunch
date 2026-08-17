-----------------------------------
-- Shock Squall
-- Family: Ramuh (Player Pet)
-----------------------------------
---@type TAbilityPet
local abilityObject = {}

abilityObject.onAbilityCheck = function(player, target, ability)
    return xi.job_utils.summoner.canUseBloodPact(player, player:getPet(), target, ability)
end

abilityObject.onPetAbility = function(target, pet, petskill, summoner, action)
    xi.job_utils.summoner.onUseBloodPact(target, petskill, summoner, action)

    local result = xi.mobskills.mobStatusEffectMove(pet, target, xi.effect.STUN, 1, 0, 15)

    petskill:setMsg(result)
    return xi.effect.STUN
end

return abilityObject
