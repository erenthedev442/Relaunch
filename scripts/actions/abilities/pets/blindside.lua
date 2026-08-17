-----------------------------------
-- Blindside
-- Family: Diabolos (Player Pet)
-----------------------------------
---@type TAbilityPet
local abilityObject = {}

abilityObject.onAbilityCheck = function(player, target, ability)
    return xi.job_utils.summoner.canUseBloodPact(player, player:getPet(), target, ability)
end

abilityObject.onPetAbility = function(target, pet, petskill, summoner, action)
    xi.job_utils.summoner.onUseBloodPact(target, petskill, summoner, action)

    local info = xi.summon.avatarPhysicalMove(
        pet, target, petskill, 1, 1, 4.0, 0,
        xi.mobskills.physicalTpBonus.DMG_VARIES, 1.5, 2.0, 2.5)
    local damage = xi.summon.avatarFinalAdjustments(
        info, pet, petskill, target, xi.attackType.PHYSICAL, xi.damageType.SLASHING, 1)

    target:takeDamage(damage, pet, xi.attackType.PHYSICAL, xi.damageType.SLASHING)
    target:updateEnmityFromDamage(pet, damage)

    return damage
end

return abilityObject
