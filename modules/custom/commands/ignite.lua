-----------------------------------
-- func: ignite
-- desc: Boom job buff. Coats your staff in volatile energy: grants an elemental
--       enspell (added melee damage) and opens a window where your spells
--       detonate far more often. Only works while Boom (the repurposed Summoner
--       slot) is your MAIN job.
--
-- Usage: !ignite
--
-- Logic lives in BoomJob.lua (xi.boomJob.ignite). Hot-reloads as a command.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    if xi.boomJob and xi.boomJob.ignite then
        xi.boomJob.ignite(player)
    else
        player:printToPlayer('[Boom] Module not loaded (needs a map restart).', xi.msg.channel.SYSTEM_3)
    end
end

return commandObj
