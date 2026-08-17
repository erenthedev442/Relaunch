-----------------------------------
-- Pacifying Ruby
-- Family: Carbuncle (Player Pet)
-----------------------------------
---@type TAbilityPet
local abilityObject = {}

abilityObject.onAbilityCheck = function(player, target, ability)
    return xi.job_utils.summoner.canUseBloodPact(player, player:getPet(), target, ability)
end

abilityObject.onPetAbility = function(target, pet, petskill, summoner, action)
    xi.job_utils.summoner.onUseBloodPact(target, petskill, summoner, action)

    local affected = 0
    for _, mob in pairs(target:getNotorietyList()) do
        if mob:isMob() then
            mob:lowerEnmity(target, 25)
            affected = affected + 1
        end
    end

    if affected == 0 then
        petskill:setMsg(xi.msg.basic.JA_NO_EFFECT_2)
        return 0
    end

    petskill:setMsg(xi.msg.basic.JA_ENMITY_DECREASE)
    return affected
end

return abilityObject
