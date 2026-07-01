-----------------------------------
-- func: gc_full
-- desc: Tell Lua to run a full garbage collection
-- note: For testing only (GM level 5)
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = ''
}

commandObj.onTrigger = function(player)
    GarbageCollectFull()
end

return commandObj
