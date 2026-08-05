-----------------------------------
-- Generic jug pet skill
-----------------------------------
---@type TAbilityPet
local abilityObject = {}
local skillName = 'fluid_spread'

abilityObject.onAbilityCheck = function(player, target, ability)
    return 0
end

abilityObject.onPetAbility = function(target, pet, petskill, owner, action)
    local skill = xi.actions.mobskills[skillName]
    if not skill or not skill.onMobWeaponSkill then
        return 0
    end

    return skill.onMobWeaponSkill(pet, target, petskill, action)
end

return abilityObject
