-----------------------------------
-- Ultimate Terror
-- Family: Diabolos (Player Pet)
-----------------------------------
---@type TAbilityPet
local abilityObject = {}

local attributesDown =
{
    xi.effect.STR_DOWN,
    xi.effect.DEX_DOWN,
    xi.effect.VIT_DOWN,
    xi.effect.AGI_DOWN,
    xi.effect.MND_DOWN,
    xi.effect.INT_DOWN,
    xi.effect.CHR_DOWN,
}

abilityObject.onAbilityCheck = function(player, target, ability)
    return xi.job_utils.summoner.canUseBloodPact(player, player:getPet(), target, ability)
end

abilityObject.onPetAbility = function(target, pet, petskill, summoner, action)
    xi.job_utils.summoner.onUseBloodPact(target, petskill, summoner, action)

    local numToDrain = math.random(0, #attributesDown)
    local shuffled = utils.shuffle(attributesDown)
    local drained = 0

    for i = 1, numToDrain do
        if
            xi.mobskills.mobDrainAttribute(pet, target, shuffled[i], 21, 3, 90) ==
            xi.msg.basic.ATTR_DRAINED
        then
            drained = drained + 1
        end
    end

    if drained > 0 then
        petskill:setMsg(xi.msg.basic.EFFECT_DRAINED)
    else
        petskill:setMsg(xi.msg.basic.JA_NO_EFFECT_2)
    end

    return drained
end

return abilityObject
