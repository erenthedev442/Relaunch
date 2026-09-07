-----------------------------------
-- Ability: Climactic Flourish
-- Description: Allows you to deal critical hits. Requires at least one finishing move.
-- Obtained: DNC Level 80
-- Recast Time: 00:01:30 (Flourishes III)
-- Duration: 00:01:00, or until the granted crit charges are spent
-- Cost: ALL Finishing Moves (each becomes one guaranteed crit)
-----------------------------------
require('scripts/globals/job_utils/dancer')

---@type TAbility
local abilityObject = {}

abilityObject.onAbilityCheck = function(player, target, ability)
    local fm = player:getStatusEffect(xi.effect.FINISHING_MOVE_1)
    if fm and fm:getPower() >= 1 then
        return 0, 0
    end
    return xi.msg.basic.NO_FINISHINGMOVES, 0
end

abilityObject.onUseAbility = function(player, target, ability)
    return xi.job_utils.dancer.useClimacticFlourishAbility(player, target, ability)
end

return abilityObject
