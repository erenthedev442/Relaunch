-----------------------------------
-- !hunt
-- Player shortcut to the Hunting League hub. Mirrors !warp -> Hunting League.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    player:setPos(0.0000, -0.5000, -30.0000, 128, xi.zone.ESCHA_ZITAH)
    player:printToPlayer('Warped to the Hunting League hub. Hunt well, kupo!', xi.msg.channel.SYSTEM_3)
end

return commandObj
