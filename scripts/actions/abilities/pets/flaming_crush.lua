-----------------------------------
-- Flaming Crush
-- Family: Ifrit (Player Pet)
-- Notes: Hybrid skill
-----------------------------------
---@type TAbilityPet
local abilityObject = {}
local avatarProgression = require('modules/custom/lua/smn_avatar_equalize')

abilityObject.onAbilityCheck = function(player, target, ability)
    return xi.job_utils.summoner.canUseBloodPact(player, player:getPet(), target, ability)
end

abilityObject.onPetAbility = function(target, pet, petskill, summoner, action)
    xi.job_utils.summoner.onUseBloodPact(target, petskill, summoner, action)

    local physicalInfo = xi.summon.avatarPhysicalMove(
        pet, target, petskill, 2, 1, 6, 1,
        xi.mobskills.magicalTpBonus.NO_EFFECT, 1, 1, 1)
    local damage = avatarProgression.finalizePhysicalWithoutProgression(
        physicalInfo, pet, petskill, target,
        xi.attackType.PHYSICAL, xi.damageType.BLUNT, 1)
    local magicDamage = 0

    if physicalInfo.hitslanded > 0 and damage > 0 then
        magicDamage = xi.mobskills.handleHybridDamage(
            pet, target, damage, xi.element.FIRE)
    end

    damage, magicDamage = avatarProgression.scaleHybridDamage(
        pet, target, petskill, damage, magicDamage)

    if damage > 0 then
        target:takeDamage(damage, pet, xi.attackType.PHYSICAL, xi.damageType.BLUNT)
        target:takeDamage(magicDamage, pet, xi.attackType.MAGICAL, xi.damageType.FIRE)
        target:updateEnmityFromDamage(pet, damage + magicDamage)
    end

    xi.summon.reportPetOverCap(pet, damage + magicDamage)

    return damage + magicDamage
end

return abilityObject
