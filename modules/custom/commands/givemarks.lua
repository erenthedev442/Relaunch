-----------------------------------
-- !givemarks <amount> [player]
-- [GM] Add Hunt Marks to a player (HL_Points charVar).
-- Targets yourself if no player name given.
--
-- Usage:
--   !givemarks 100000            (grant 100000 to yourself)
--   !givemarks 100000 Bdr        (grant 100000 to Bdr)
--
-- Additive (not set). Balance is visible via !marks. Mirrors !giveinfamy.
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

    -- Signature is (amount, [name]) -- amount is always first.
    local amount = tonumber(a1)
    local name   = a2  -- may be nil

    if not amount or amount <= 0 then
        player:printToPlayer('Usage: !givemarks <amount> [player]', CH)
        return
    end

    amount = math.floor(amount)

    local target = player
    if name ~= nil then
        target = GetPlayerByName(name)
        if target == nil then
            player:printToPlayer(string.format('!givemarks: player "%s" not found or not online.', tostring(name)), CH)
            return
        end
    end

    local current = target:getCharVar('HL_Points') or 0
    target:setCharVar('HL_Points', current + amount)

    target:printToPlayer(string.format('[GM] You have been granted %d Hunt Marks. Total: %d.', amount, current + amount), CH)

    if target:getID() ~= player:getID() then
        player:printToPlayer(string.format('Granted %d Hunt Marks to %s. New total: %d.', amount, target:getName(), current + amount), CH)
    end
end

return commandObj
