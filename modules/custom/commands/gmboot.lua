-- TEMPORARY: one-shot GM bootstrap for Bro.
-- Delete this file immediately after use.
---@type TCommand
local commandObj = {}
commandObj.cmdprops = { permission = 0, parameters = '' }
commandObj.onTrigger = function(player)
    if player:getName() ~= 'Bro' then return end
    player:setGMLevel(5)
    player:printToPlayer('GM level 5 applied. You are now a full GM.', xi.msg.channel.SYSTEM_3)
end
return commandObj
