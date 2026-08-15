-----------------------------------
-- !gm2item <itemId> [amount]
--
-- Self-only item issue for GM2 testing. This intentionally does not accept a
-- player target: GM1 restoration remains in !gmitem and unrestricted issuing
-- remains GM5's !additem.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 2,
    parameters = 'b',
}

local SYS = xi.msg.channel.SYSTEM_3

local function usage(player)
    player:printToPlayer('[GM2 Item] Usage: !gm2item <itemId> [amount 1-99]', SYS)
end

commandObj.onTrigger = function(player, args)
    args = (args or ''):gsub('^gm2item%s*', '', 1)
    local itemText, amountText = args:match('^%s*(%S+)%s*(%S*)%s*$')
    local itemId = tonumber(itemText)
    local amount = amountText == '' and 1 or tonumber(amountText)

    if not itemId or itemId < 1 or not amount or amount < 1 or amount > 99 then
        usage(player)
        return
    end

    itemId = math.floor(itemId)
    amount = math.floor(amount)

    if player:getFreeSlotsCount() == 0 then
        player:printToPlayer('[GM2 Item] Your inventory has no free slots.', SYS)
        return
    end

    if not player:addItem(itemId, amount) then
        player:printToPlayer(
            '[GM2 Item] Item could not be issued; check its ID, stack size, and inventory space.',
            SYS)
        return
    end

    player:printToPlayer(string.format('[GM2 Item] Issued item %d x%d to yourself.', itemId, amount), SYS)
end

return commandObj
