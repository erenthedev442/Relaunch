-----------------------------------
-- func: hunt2
-- desc: Warps you to the Tier 2 (Rank II - Hunter) hunt spawner in Escha - Zi'Tah.
--       NMs: Roc, Bomb Queen, Aquarius.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 5,
    parameters = ''
}

commandObj.onTrigger = function(player)
    player:setPos(40.9101, 0.4831, 132.8770, 71, xi.zone.ESCHA_ZITAH)
    player:printToPlayer('Warped to Tier 2 hunt cluster (Rank II - Hunter). Good luck!', xi.msg.channel.SYSTEM_3)
end

return commandObj
