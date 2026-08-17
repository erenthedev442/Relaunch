-----------------------------------
-- Generic jug pet skill
-----------------------------------
---@type TAbilityPet
local abilityObject = {}
local skillName = 'stink_bomb'

abilityObject.onAbilityCheck = function(player, target, ability)
    return 0
end

abilityObject.onPetAbility = function(target, pet, petskill, owner, action)
    return xi.actions.mobskills[skillName].onMobWeaponSkill(pet, target, petskill, action)
end

return abilityObject
