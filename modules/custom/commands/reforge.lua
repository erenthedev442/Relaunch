-----------------------------------
-- func: reforge
-- desc: Shows the player's Reforge AF, Relic, and Empy mark balances.
--
-- Usage: !reforge
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

local H = xi.msg.channel.SYSTEM_3
local B = xi.msg.channel.SYSTEM_1

commandObj.onTrigger = function(player)
    local afMarks    = player:getCharVar('RF_AF_Marks')    or 0
    local relicMarks = player:getCharVar('RF_Relic_Marks') or 0
    local empyMarks  = player:getCharVar('RF_Empy_Marks')  or 0

    player:printToPlayer('[Reforge] == Mark Balances ============================', H)
    player:printToPlayer(string.format('  Artifact (AF) marks:   %d', afMarks),    B)
    player:printToPlayer(string.format('  Relic marks:           %d', relicMarks), B)
    player:printToPlayer(string.format('  Empyrean marks:        %d', empyMarks),  B)
    player:printToPlayer('  ==================================================', B)
    player:printToPlayer('  Earn Reforge marks by killing Hunting League NMs.', B)
    player:printToPlayer('  Spend them at the Reforge NPC in Reisenjima Henge.', B)
    player:printToPlayer('  !progress reforge - full breakdown  |  !hunt - warp there', B)
end

return commandObj
