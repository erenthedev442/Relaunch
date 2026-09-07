-----------------------------------
-- func: home
-- desc: Sends the caller to their homepoint.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = ''
}

commandObj.onTrigger = function(player)
    if require('modules/custom/lua/travel_guard').refuseTravel(player) then
        return
    end

    player:warp()
end

return commandObj
