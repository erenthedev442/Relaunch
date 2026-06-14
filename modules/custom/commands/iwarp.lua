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

local DEST = { x = 0, y = 0, z = 36, rot = 0 }

commandObj.onTrigger = function(player)
    player:teleport(DEST, xi.zone.AL_ZAHBI)
end

return commandObj
