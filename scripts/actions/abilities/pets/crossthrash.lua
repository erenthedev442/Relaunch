-----------------------------------
-- Generic jug pet skill
-- TODO: verify functionality with regards to jug pet differences from regular mobs
-----------------------------------
---@type TAbilityPet
local abilityObject = {}
local skillName = 'crossthrash'

abilityObject.onAbilityCheck = function(player, target, ability)
    return 0
end

abilityObject.onPetAbility = function(target, pet, petskill, owner, action)
    return xi.actions.mobskills[skillName].onMobWeaponSkill(pet, target, petskill, action)
end

return abilityObject
