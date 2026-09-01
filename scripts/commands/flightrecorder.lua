-----------------------------------
-- func: flightrecorder
-- desc: Print the crash flight recorder (who is in which zone/instance).
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = ''
}

commandObj.onTrigger = function(player)
    local snapshot = GetCrashSnapshot()
    if snapshot == nil or snapshot == '' then
        player:printToPlayer('Flight recorder is empty.', xi.msg.channel.SYSTEM_3)
        return
    end

    player:printToPlayer('Flight recorder:', xi.msg.channel.SYSTEM_3)
    for line in string.gmatch(snapshot, '[^\r\n]+') do
        player:printToPlayer(line, xi.msg.channel.SYSTEM_3)
    end
end

return commandObj
