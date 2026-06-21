-----------------------------------
-- func: hunt4
-- desc: Warps you to the Tier 4 (Rank IV - Champion) hunt spawner in Escha - Zi'Tah.
--       NMs: Nidhogg, King Behemoth, Kirin.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = ''
}

commandObj.onTrigger = function(player)
    player:setPos(22.0112, 0.8983, -121.4367, 126, xi.zone.ESCHA_ZITAH)
    player:printToPlayer('Warped to Tier 4 hunt cluster (Rank IV - Champion). Good luck!', xi.msg.channel.SYSTEM_3)
end

return commandObj
