-----------------------------------
-- func: autoready
-- desc: Toggles automatic Ready moves for the player's BST jug pets.
--
-- Usage: !autoready [on|off|status]
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 's',
}

local AUTO_READY_OFF_VAR = 'BST_AutoReadyOff'
local SYS = xi.msg.channel.SYSTEM_3

local function isEnabled(player)
    return (player:getCharVar(AUTO_READY_OFF_VAR) or 0) == 0
end

local function printStatus(player, enabled)
    if enabled then
        player:printToPlayer(
            '[BST Auto-Ready] ON - your engaged jug pet will use a random Ready move at 1,000 TP.',
            SYS)
    else
        player:printToPlayer(
            '[BST Auto-Ready] OFF - use Ready or Sic manually. Run !autoready to enable it again.',
            SYS)
    end
end

commandObj.onTrigger = function(player, mode)
    mode = string.lower(mode or '')

    if mode == 'status' then
        printStatus(player, isEnabled(player))
        return
    end

    local enabled
    if mode == 'on' then
        enabled = true
    elseif mode == 'off' then
        enabled = false
    elseif mode == '' then
        enabled = not isEnabled(player)
    else
        player:printToPlayer('Usage: !autoready [on|off|status]', SYS)
        return
    end

    player:setCharVar(AUTO_READY_OFF_VAR, enabled and 0 or 1)
    printStatus(player, enabled)
end

return commandObj
