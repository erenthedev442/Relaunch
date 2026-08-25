-----------------------------------
-- !reforged
-- Player shortcut to the Reforge hub. Mirrors !warp -> Progression Hubs.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    player:setPos(-0.66, 0.0, -3.10, 143, xi.zone.DIORAMA_ABDHALJS_GHELSBA)
    player:printToPlayer('Warped to the Reforge hub. Reforge well, kupo!', xi.msg.channel.SYSTEM_3)
end

return commandObj
