-----------------------------------
-- func: hunt1
-- desc: Warps you to the Tier 1 (Rank I - Initiate) hunt spawner in Escha - Zi'Tah.
--       NMs: Leaping Lizzy, Valkurm Emperor, Tom Tit Tat.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = ''
}

commandObj.onTrigger = function(player)
    player:setPos(-41.5941, 0.1103, 73.7704, 176, xi.zone.ESCHA_ZITAH)
    player:printToPlayer('Warped to Tier 1 hunt cluster (Rank I - Initiate). Good luck!', xi.msg.channel.SYSTEM_3)
end

return commandObj
