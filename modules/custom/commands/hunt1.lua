-----------------------------------
-- !hunt1
-- Player shortcut to Hunting League tier 1.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    player:setPos(-41.5941, 0.1103, 73.7704, 176, xi.zone.ESCHA_ZITAH)
    player:printToPlayer('Warped to Tier 1 hunt cluster. Good luck!', xi.msg.channel.SYSTEM_3)
end

return commandObj
