-----------------------------------
-- !hades
-- Reminder only: prints today's five objectives and whether each is
-- ready to turn in. Shards are paid at the Hades NPC, not here.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    local ok, hades = pcall(require, 'modules/custom/lua/hades_daily')
    if not ok or not hades or not hades.formatStatus then
        player:printToPlayer('Hades is silent right now.', xi.msg.channel.SYSTEM_3)
        return
    end
    for _, line in ipairs(hades.formatStatus(player)) do
        player:printToPlayer(line, xi.msg.channel.SYSTEM_3)
    end
end

return commandObj
