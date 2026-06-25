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
    player:setPos(5.5, -0.4, 8.1, 73, xi.zone.LEAFALLIA)
end

return commandObj
