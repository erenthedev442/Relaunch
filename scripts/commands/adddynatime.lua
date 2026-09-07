-----------------------------------
-- func: adddynatime
-- desc: Adds an amount of time to the given target. If no target then to the current player.
-----------------------------------
require('scripts/globals/dynamis')
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
    player:printToPlayer('!adddynatime <minutes> (player)')
end

commandObj.onTrigger = function(player, minutes, target)
    -- validate target
    local targ
    if target == nil then
        targ = player
    else
        targ = GetPlayerByName(target)
        if targ == nil then
            error(player, string.format('Player named "%s" not found!', target))
            return
        end
    end

    -- target must be in dynamis
    local effect = targ:getStatusEffect(xi.effect.DYNAMIS)
    if not effect then
        error(player, string.format('%s is not in Dynamis.', targ:getName()))
        return
    end

    -- validate amount
    if minutes == nil or minutes < 1 then
        error(player, 'Invalid number of minutes.')
        return
    end

    -- add time (same remaining + resetStartTime path as statue TEs)
    if not xi.dynamis.applyTimeExtension(targ, minutes) then
        error(player, string.format('Could not extend Dynamis time for %s.', targ:getName()))
    end
end

return commandObj
