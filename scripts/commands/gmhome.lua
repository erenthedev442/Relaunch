-----------------------------------
-- func: gmhome
-- desc: Sends you to zone 210 (GM_HOME), if you are a GM
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = ''
}

commandObj.onTrigger = function(player)
    player:setPos(521.5545, -3.0378, 544.2744, 65, xi.zone.ABDHALJS_ISLE_PURGONORGO)
end

return commandObj
