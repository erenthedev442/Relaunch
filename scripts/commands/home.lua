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
    player:warp()
end

return commandObj
