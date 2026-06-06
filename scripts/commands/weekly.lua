-----------------------------------
-- func: weekly
-- desc: Displays the player's current Weekly Hunt Board progress —
--       the 5 rolled objectives, per-objective progress, and the
--       lifetime "Weekly Hunter" sweep counter.
--
-- Objectives auto-roll on the first interaction of each new week
-- (ISO week, Monday 00:00 UTC). See modules/custom/lua/weekly_hunts.lua.
-----------------------------------
local wh = require('modules/custom/lua/weekly_hunts')

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    for _, line in ipairs(wh.formatStatus(player)) do
        player:printToPlayer(line, xi.msg.channel.SYSTEM_3)
    end
end

return commandObj
