-----------------------------------
-- !hunt2
-- Player shortcut to Hunting League tier 2.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    player:setPos(40.9101, 0.4831, 132.8770, 71, xi.zone.ESCHA_ZITAH)
    player:printToPlayer('Warped to Tier 2 hunt cluster. Good luck!', xi.msg.channel.SYSTEM_3)
end

return commandObj
