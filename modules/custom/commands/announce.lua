-----------------------------------
-- func: announce
-- desc: GM command. Broadcasts a custom notice to every zone.
--
-- Usage (GM only):
--   !announce <message>
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,   -- GM only
    parameters = 's',
}

commandObj.onTrigger = function(player, message)
    if not message or message == '' then
        player:printToPlayer('[announce] Usage: !announce <message>', xi.msg.channel.SYSTEM_3)
        return
    end

    local broadcastMsg = string.format('[NOTICE] %s', message)
    player:printToArea(broadcastMsg, xi.msg.channel.SYSTEM_3, xi.msg.area.SYSTEM, '', true)

    -- Confirmation to the GM.
    player:printToPlayer(
        string.format('[announce] Broadcast sent: "%s"', message),
        xi.msg.channel.SYSTEM_3)
end

return commandObj
