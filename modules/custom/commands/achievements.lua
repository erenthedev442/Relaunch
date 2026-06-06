-----------------------------------
-- func: achievements
-- desc: Shows all personal milestone achievements - earned and unearned -
--       with their reward amounts and descriptions.
--
--       Milestones are defined in modules/custom/lua/achievements.lua.
--       Each milestone stores its completion timestamp in the CharVar
--       'ACH_<id>' (non-zero = earned).
--
-- Usage: !achievements
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

local ach = require('modules/custom/lua/achievements')

local H = xi.msg.channel.SYSTEM_3
local B = xi.msg.channel.LINKSHELL

commandObj.onTrigger = function(player)
    player:printToPlayer('[Achievements] == Your Personal Milestones ==============', H)

    local earned = 0
    local total  = #ach.MILESTONES

    for _, ms in ipairs(ach.MILESTONES) do
        local achVar = 'ACH_' .. ms.id
        local done   = (player:getCharVar(achVar) or 0) ~= 0
        if done then earned = earned + 1 end

        local tag    = done and '[DONE]' or '[----]'
        local reward = string.format('+%d marks', ms.reward)
        player:printToPlayer(
            string.format('  %s %-22s  (%s)  - %s',
                tag, ms.title, reward, ms.desc), B)
    end

    player:printToPlayer(
        string.format('[Achievements] Earned: %d / %d  milestones', earned, total), H)
end

return commandObj
