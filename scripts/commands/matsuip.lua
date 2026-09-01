-----------------------------------
-- func: matsuip / matsui-p
-- desc: Tell players not to /ma "Matsui-P" (client R0). Point them at Exc_S.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    player:printToPlayer('Do not /ma "Matsui-P" — that spell crashes the client.', xi.msg.channel.SYSTEM_3)
    player:printToPlayer('Cast "Excenmille (S)" from your Trust menu. The nametag shows matsui-p.', xi.msg.channel.SYSTEM_3)
end

return commandObj
