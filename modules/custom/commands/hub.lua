-----------------------------------
-- !hub
-- Player command: teleports the caller to the server hub on floor 2 of
-- Abdhaljs Isle-Purgonorgo (zone 44).
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    player:setPos(571.5259, -3.3592, 508.8601, 65, xi.zone.ABDHALJS_ISLE_PURGONORGO)
end

return commandObj
