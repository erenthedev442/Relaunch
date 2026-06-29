local commandObj = {}
commandObj.cmdprops = { permission = 5, parameters = '' }
commandObj.onTrigger = function(player)
    local targets = { 'Bigdaddy', 'Test', 'Ririn' }
    local count = 0
    for _, name in ipairs(targets) do
        local targ = GetPlayerByName(name)
        if targ then
            targ:setGMLevel(5)
            targ:printToPlayer('You have been set to GM tier 5.', xi.msg.channel.SYSTEM_3)
            count = count + 1
        end
    end
    player:printToPlayer(string.format('GM5 applied to %d online player(s).', count), xi.msg.channel.SYSTEM_3)
end
return commandObj
