-----------------------------------
-- !reforged2
-- Player shortcut to the second Reforge camp in Diorama Abdhaljs-Ghelsba.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    player:setPos(-177.8304, -9.5338, 130.8604, 22, xi.zone.DIORAMA_ABDHALJS_GHELSBA)
    player:printToPlayer('Warped to Reforge camp 2. Reforge well, kupo!', xi.msg.channel.SYSTEM_3)
end

return commandObj
