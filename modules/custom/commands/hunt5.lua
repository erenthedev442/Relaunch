-----------------------------------
-- !hunt5
-- Player shortcut to Hunting League tier 5.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    player:setPos(433.8451, 0.1066, -199.3157, 119, xi.zone.ESCHA_ZITAH)
    player:printToPlayer('Warped to Tier 5 hunt cluster. Good luck!', xi.msg.channel.SYSTEM_3)
end

return commandObj
