-----------------------------------
-- func: costume
-- desc: Sets the current costume on you, your cursor target, or a named player.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 5,
    parameters = 'is'
}

local function error(player, msg)
    player:printToPlayer(msg)
    player:printToPlayer('!costume <costumeID> (player)')
end

commandObj.onTrigger = function(player, costumeId, target)
    if costumeId == nil or costumeId < 0 then
        error(player, 'Invalid costumeID.')
        return
    end

    local targ
    local cursorTarget = player:getCursorTarget()

    if target then
        targ = GetPlayerByName(target)
        if not targ then
            error(player, string.format('Player named "%s" not found!', target))
            return
        end
    elseif cursorTarget and cursorTarget:isPC() then
        targ = cursorTarget
    else
        targ = player
    end

    targ:setCostume(costumeId)
    if targ:getID() ~= player:getID() then
        player:printToPlayer(string.format('Set %s\'s costume to %d.', targ:getName(), costumeId))
    end
end

return commandObj
