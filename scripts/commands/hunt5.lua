-----------------------------------
-- func: hunt5
-- desc: Warps you to the Tier 5 (Rank V - Legend) hunt spawner in Escha - Zi'Tah.
--       NMs: Absolute Virtue, Pandemonium Warden, Shinryu.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 5,
    parameters = ''
}

commandObj.onTrigger = function(player)
    player:setPos(433.8451, 0.1066, -199.3157, 119, xi.zone.ESCHA_ZITAH)
    player:printToPlayer('Warped to Tier 5 hunt cluster (Rank V - Legend). Good luck!', xi.msg.channel.SYSTEM_3)
end

return commandObj
