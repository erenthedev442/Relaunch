-----------------------------------
-- func: releaseme
-- desc: Legacy alias for !unstick.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    require('scripts/commands/unstick').onTrigger(player)
end

return commandObj
