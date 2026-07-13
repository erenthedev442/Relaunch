-----------------------------------
-- Ability: Climactic Flourish
-- Description: Allows you to deal critical hits. Requires at least one finishing move.
-- Obtained: DNC Level 80
-- Recast Time: 00:01:30 (Flourishes III)
-- Duration: 00:01:00 (or the next weaponskill, whichever comes first)
-- Cost: 1 Finishing Move
--
-- RELAUNCH FIX 2026-07-13 (Jamesta report): the stock effect was a bare stub
-- so this ability did nothing. Real implementation lives in
--   scripts/globals/job_utils/dancer.lua      (spends 1 FM, applies the effect)
--   scripts/effects/climactic_flourish.lua    (adds CRITHITRATE+100, CDI+50)
--   modules/custom/lua/climactic_flourish_consumer.lua  (removes on next WS)
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
