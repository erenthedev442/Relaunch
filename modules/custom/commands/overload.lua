-----------------------------------
-- func: overload
-- desc: Boom job ultimate (Astral-Flow style). Unleashes one massive elemental
--       detonation on your target (with an AoE blast), on a long cooldown.
--       Only works while Boom (the repurposed Summoner slot) is your MAIN job.
--
-- Usage: !overload   (engage an enemy first)
--
-- Logic lives in BoomJob.lua (xi.boomJob.overload). Hot-reloads as a command.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    if xi.boomJob and xi.boomJob.overload then
        xi.boomJob.overload(player)
    else
        player:printToPlayer('[Boom] Module not loaded (needs a map restart).', xi.msg.channel.SYSTEM_3)
    end
end

return commandObj
