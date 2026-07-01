-----------------------------------
-- func: capallskills
-- desc: Caps all the players skills.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = ''
}

commandObj.onTrigger = function(player)
    player:capAllSkills()
    player:printToPlayer('All skills capped!')
end

return commandObj
