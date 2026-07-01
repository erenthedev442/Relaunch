-----------------------------------
-- func: reloadrecipes
-- desc: Reloads crafting recipes from the DB
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = ''
}

commandObj.onTrigger = function(player)
    ReloadSynthRecipes()
end

return commandObj
