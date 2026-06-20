require('modules/module_utils')
local m = Module:new('ranged_no_distance_penalty')

-- Remove the sweet-spot distance penalty system. Ranged attackers no longer
-- suffer rATT or rACC penalties for standing too close or too far from their target.
xi.combat.ranged.attackDistancePenalty  = function() return 0 end
xi.combat.ranged.accuracyDistancePenalty = function() return 0 end

return m
