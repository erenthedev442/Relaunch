-----------------------------------
-- Ability: Hover Shot
-- Description: Builds ranged accuracy and attack when attacking from
--              a position at least 1 yalm from the previous attack.
--              Up to 25 stacks (+4 RACC, +30 RATT each). Resets on
--              same-position shot or target switch.
-- Obtained: RNG Level 95
-- Recast Time: 00:03:00
-- Duration: 01:00:00
-- Overwrites / overwritten by: Decoy Shot
-----------------------------------
---@type TAbility
local abilityObject = {}

abilityObject.onAbilityCheck = function(player, target, ability)
    return xi.job_utils.ranger.checkHoverShot(player, target, ability)
end

abilityObject.onUseAbility = function(player, target, ability, action)
    return xi.job_utils.ranger.useHoverShot(player, target, ability, action)
end

return abilityObject
