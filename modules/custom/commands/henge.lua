-----------------------------------
-- !henge
-- Warps the player to Reisenjima Henge (!hunt zone).
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
    player:setPos(0, 0, 0, 0, xi.zone.REISENJIMA_HENGE)
end

return commandObj
