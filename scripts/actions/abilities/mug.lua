-----------------------------------
-- Ability: Mug
-- Steal gil from enemy. Main THF also drains HP (see thief_mug_catalog).
-- Obtained: Thief Level 35
-- Recast Time: 5:00 (/THF). Main THF: 90s.
-----------------------------------
---@type TAbility
local abilityObject = {}

abilityObject.onAbilityCheck = function(player, target, ability)
    return xi.job_utils.thief.checkMug(player, target, ability)
end

abilityObject.onUseAbility = function(player, target, ability, action)
    return xi.job_utils.thief.useMug(player, target, ability, action)
end

return abilityObject
