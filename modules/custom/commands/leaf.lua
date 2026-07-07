-----------------------------------
-- !leafallia
-- Warps the player to Leafallia (the relaunch hub zone).
-- Available to all players (permission 0).
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    player:setPos(521.5545, -3.0378, 544.2744, 65, xi.zone.ABDHALJS_ISLE_PURGONORGO)
end

return commandObj
