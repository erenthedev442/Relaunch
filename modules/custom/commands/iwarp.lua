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
    player:setPos(0, 0, 36, 0, xi.zone.AL_ZAHBI)
end

return commandObj
