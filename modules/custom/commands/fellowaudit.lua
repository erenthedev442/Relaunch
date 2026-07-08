-----------------------------------
-- func: fellowaudit
-- desc: Audits the summoned Fellow -- for every mod the build should add, shows
--       EXPECTED (from your allocations/level/role) vs the LIVE getMod on the pet,
--       flagging anything that didn't land. Proves boosting a stat reaches the
--       entity. Fellow must be summoned.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    if not (xi.fellow and xi.fellow.audit) then
        player:printToPlayer('[Fellow] Fellow system not loaded yet.', xi.msg.channel.SYSTEM_3)
        return
    end
    xi.fellow.audit(player)
end

return commandObj
