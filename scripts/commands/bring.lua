-----------------------------------
-- func: bring <player>
-- desc: Brings the target to the player.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = 'si'
}

local function error(player, msg)
    player:printToPlayer(msg)
    player:printToPlayer('!bring <player> (forceZone)')
end

commandObj.onTrigger = function(player, target, forceZone)
    -- validate target
    if target == nil then
        error(player, 'You must enter a target player name.')
        return
    end

    local targ = GetPlayerByName(target)
    if targ == nil then
        if player:getGMLevel() < 5 then
            error(player, 'Target is not on this map process. Switch clusters before using !bring.')
            return
        end
        if not player:bringPlayer(target) then
            error(player, string.format('Player named "%s" not found!', target))
        end

        return
    end

    if player:getGMLevel() < 5 and (targ:getGMLevel() or 0) > 0 then
        error(player, 'GM1 cannot move another staff character.')
        return
    end

    -- validate forceZone
    if forceZone ~= nil then
        if forceZone ~= 0 and forceZone ~= 1 then
            error(player, 'If provided, forceZone must be 1 (true) or 0 (false).')
            return
        end
    else
        forceZone = 1
    end

    -- bring target
    if targ:getZoneID() ~= player:getZoneID() or forceZone == 1 then
        targ:setPos(player:getXPos(), player:getYPos(), player:getZPos(), player:getRotPos(), player:getZoneID())
    else
        targ:setPos(player:getXPos(), player:getYPos(), player:getZPos(), player:getRotPos())
    end
end

return commandObj
