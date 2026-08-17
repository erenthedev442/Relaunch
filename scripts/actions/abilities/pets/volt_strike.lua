-----------------------------------
-- Volt Strike
-- Family: Ramuh (Player Pet)
-----------------------------------
---@type TAbilityPet
local abilityObject = {}

abilityObject.onAbilityCheck = function(player, target, ability)
    return xi.job_utils.summoner.canUseBloodPact(player, player:getPet(), target, ability)
end

abilityObject.onPetAbility = function(target, pet, petskill, summoner, action)
    xi.job_utils.summoner.onUseBloodPact(target, petskill, summoner, action)

    local info = xi.summon.avatarPhysicalMove(
        pet, target, petskill, 3, 1, 5.3, 5.3,
        xi.mobskills.physicalTpBonus.CRIT_VARIES, 1, 2, 3)
    local damage = xi.summon.avatarFinalAdjustments(
        info, pet, petskill, target, xi.attackType.PHYSICAL, xi.damageType.BLUNT, 3)

    if info.hitslanded > 0 then
        target:addStatusEffect(xi.effect.STUN, { power = 1, duration = 15, origin = pet })
    end

    target:takeDamage(damage, pet, xi.attackType.PHYSICAL, xi.damageType.BLUNT)
    target:updateEnmityFromDamage(pet, damage)

    return damage
end

return abilityObject
