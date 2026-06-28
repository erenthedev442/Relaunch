-----------------------------------
-- func: fellowstats
-- desc: Dumps live mod values straight off the spawned Fellow pet.
--       Fellow must be summoned. Spend a point, re-run, watch the number move.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    if not xi.fellow then
        player:printToPlayer('[Fellow] Fellow system not loaded yet.', xi.msg.channel.SYSTEM_3)
        return
    end
    xi.fellow.debug(player)
end

return commandObj
