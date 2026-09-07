-----------------------------------
-- !setup
-- Re-run first-login unlocks if the player zoned, warped, or crashed
-- before Setup Complete. Jobs are idempotent.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

local SYS = xi.msg.channel.SYSTEM_3

commandObj.onTrigger = function(player)
    local upgrade = xi.characterUpgrade
    if not upgrade or not upgrade.resume then
        player:printToPlayer('Character setup is not available right now.', SYS)
        return
    end

    if upgrade.isComplete(player) then
        player:printToPlayer('Your character setup is already complete.', SYS)
        return
    end

    if player:getLocalVar('AutoUnlock_Running') == 1 then
        player:printToPlayer('Setup is still running -- you cannot move until Setup Complete, kupo!', 0, 'Unlocker')
        return
    end

    upgrade.resume(player, { delayMs = 500 })
end

return commandObj
