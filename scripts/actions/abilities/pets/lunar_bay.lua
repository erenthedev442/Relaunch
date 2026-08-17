-----------------------------------
-- Lunar Bay
-- Family: Fenrir (Player Pet)
-----------------------------------
---@type TAbilityPet
local abilityObject = {}

abilityObject.onAbilityCheck = function(player, target, ability)
    return xi.job_utils.summoner.canUseBloodPact(player, player:getPet(), target, ability)
end

abilityObject.onPetAbility = function(target, pet, petskill, summoner, action)
    xi.job_utils.summoner.onUseBloodPact(target, petskill, summoner, action)

    local moonBonus = (100 - VanadielMoonPhase()) / 100
    local params = {}

    params.baseDamage      = pet:getMainLvl() + 2
    params.fTP             = { 5.0 + moonBonus, 6.0 + moonBonus, 7.0 + moonBonus }
    params.int_wSC         = 0.30
    params.element         = xi.element.DARK
    params.attackType      = xi.attackType.MAGICAL
    params.damageType      = xi.damageType.DARK
    params.shadowBehavior  = xi.mobskills.shadowBehavior.NUMSHADOWS_1
    params.dStatMultiplier = 1.5
    params.canMagicBurst   = true
    params.primaryMessage  = xi.msg.basic.USES_JA_TAKE_DAMAGE

    local info = xi.mobskills.mobMagicalMove(pet, target, petskill, action, params)

    if xi.mobskills.processDamage(pet, target, petskill, action, info) then
        target:takeDamage(info.damage, pet, info.attackType, info.damageType)
    end

    return info.damage
end

return abilityObject
