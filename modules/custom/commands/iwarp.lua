-----------------------------------
-- !iwarp
-- Warps the player to Al Zahbi for the invasion event.
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
    player:setPos(40.8, -1.4, 116.3, 0, xi.zone.AL_ZAHBI)
end

return commandObj
