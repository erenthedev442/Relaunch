-----------------------------------
-- func: voidspire
-- desc: Warps the player to The Voidspire Wardens in Escha - Ru'Aun.
--
-- Usage: !voidspire
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    player:setPos(2.0, -34.0, -463.0, 128, xi.zone.ESCHA_RUAUN)
    player:printToPlayer('[Voidspire] Warping to The Voidspire Warden.', xi.msg.channel.SYSTEM_3)
end

return commandObj
