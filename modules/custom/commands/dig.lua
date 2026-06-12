-----------------------------------
-- func: dig
-- desc: Treasure Hunting - dig for the strongbox your treasure map
--       points at. Maps drop from Hunting League kills.
--
-- Usage: !dig
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

commandObj.onTrigger = function(player)
    local ok, th = pcall(require, 'modules/custom/lua/TreasureHunt')
    if ok and th and th.onDig then
        th.onDig(player)
    else
        player:printToPlayer('[Treasure] The treasure system is unavailable.',
            xi.msg.channel.SYSTEM_3)
    end
end

return commandObj
