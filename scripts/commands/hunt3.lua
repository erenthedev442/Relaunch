-----------------------------------
-- func: hunt3
-- desc: Warps you to the Tier 3 (Rank III - Elite) hunt spawner in Escha - Zi'Tah.
--       NMs: Serket, Vrtra, Simurgh.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = ''
}

commandObj.onTrigger = function(player)
    player:setPos(48.6277, 0.8776, 18.8663, 215, xi.zone.ESCHA_ZITAH)
    player:printToPlayer('Warped to Tier 3 hunt cluster (Rank III - Elite). Good luck!', xi.msg.channel.SYSTEM_3)
end

return commandObj
