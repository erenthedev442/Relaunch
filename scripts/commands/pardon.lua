-----------------------------------
-- func: pardon
-- desc: Pardons a player from jail. (Mordion Gaol)
-- note: Works online or offline. Online targets are disconnected and
--       land in Lower Jeuno on the next login — live warp() out of
--       Mordion has been crashing the map process.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 5,
    parameters = 's'
}

commandObj.onTrigger = function(player, target)
    if target == nil then
        player:printToPlayer('You must enter a valid player name.')
        return
    end

    local jail = require('modules/custom/lua/mordion_jail')
    local targ = GetPlayerByName(target)

    if targ then
        if not jail.isJailedPlayer(targ) then
            player:printToPlayer(string.format('%s is not jailed.', targ:getName()))
            return
        end

        local message = string.format('%s is pardoning %s from jail.', player:getName(), targ:getName())
        printf(message)
        player:printToPlayer(message)
        jail.applyOnlinePardon(player, targ)
        return
    end

    local targetID = GetPlayerIDByName(target)
    if
        targetID == nil or
        targetID <= 0 or
        targetID >= 0xFFFFFFFF
    then
        player:printToPlayer(string.format('Invalid player \'%s\' given.', target))
        return
    end

    if PlayerHasValidSession(targetID) then
        player:printToPlayer(string.format("Player '%s' is online but in a different zone group (cluster). Go to that zone group to use !pardon", target))
        return
    end

    if not jail.isJailedVar(GetCharVar(targetID, 'inJail')) then
        player:printToPlayer(string.format('%s is not jailed.', target))
        return
    end

    local message = string.format('%s is pardoning %s from jail (offline).', player:getName(), target)
    printf(message)
    player:printToPlayer(message)
    jail.applyOfflinePardon(player, target)
end

return commandObj
