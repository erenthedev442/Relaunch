-----------------------------------
-- !henge
-- Warps to Reisenjima Henge (LEGACY hub; !hunt warps to the current Escha - Zi'Tah hub).
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
