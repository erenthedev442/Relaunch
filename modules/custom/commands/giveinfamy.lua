-----------------------------------
-- !giveinfamy <amount> [player]
-- [GM] Add Infamy to a player (both current and lifetime totals).
-- Targets yourself if no player name given.
--
-- Usage:
--   !giveinfamy 500            (grant 500 to yourself)
--   !giveinfamy 500 Bdr        (grant 500 to Bdr)
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 1,
    parameters = 'ss',
}

commandObj.onTrigger = function(player, a1, a2)
    local CH = xi.msg.channel.SYSTEM_3

    -- Parse: first arg could be amount (no target) or name (if numeric second arg)
    -- Signature is (amount, [name]) — amount is always first.
    local amount = tonumber(a1)
    local name   = a2  -- may be nil

    if not amount or amount <= 0 then
        player:printToPlayer('Usage: !giveinfamy <amount> [player]', CH)
        return
    end

    amount = math.floor(amount)

    local target = player
    if name ~= nil then
        target = GetPlayerByName(name)
        if target == nil then
            player:printToPlayer(string.format('!giveinfamy: player "%s" not found or not online.', tostring(name)), CH)
            return
        end
    end

    local current  = target:getCharVar('Infamy') or 0
    local lifetime = target:getCharVar('Infamy_Lifetime') or 0

    target:setCharVar('Infamy',          current  + amount)
    target:setCharVar('Infamy_Lifetime', lifetime + amount)

    target:printToPlayer(string.format('[GM] You have been granted %d Infamy. Total: %d.', amount, current + amount), CH)

    if target:getID() ~= player:getID() then
        player:printToPlayer(string.format('Granted %d Infamy to %s. New total: %d.', amount, target:getName(), current + amount), CH)
    end
end

return commandObj
