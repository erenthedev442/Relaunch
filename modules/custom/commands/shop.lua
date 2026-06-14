-----------------------------------
-- func: shop
-- desc: Spend gil on special Gobbie Dial keys.
--
-- Usage: !shop            - list available items + prices
--         !shop <number>  - purchase the numbered item (1 at a time)
--
-- Prices are in gil. Adjust the `cost` field below.
-----------------------------------
local H = xi.msg.channel.SYSTEM_3

-- Item catalog. Add / remove rows freely; numbering is automatic.
-- Prices are in gil.
local ITEMS =
{
    { name = 'Special Gobbiedial Key', id = 8973, cost = 50000 },
    { name = 'Dial Key (AB)',          id = 9217, cost = 30000 },
    { name = 'Dial Key (FO)',          id = 9218, cost = 30000 },
    { name = 'Dial Key (ANV)',         id = 9274, cost = 30000 },
}

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = 'i',
}

commandObj.onTrigger = function(player, choice)
    local gil = player:getGil()

    if choice == nil then
        player:printToPlayer('[Shop] == Gobbie Dial Keys ==========================', H)
        player:printToPlayer(string.format('  Your Gil: %d', gil), H)
        player:printToPlayer('  ---------------------------------------------------', H)
        for i, item in ipairs(ITEMS) do
            player:printToPlayer(
                string.format('  %d) %-28s %d gil', i, item.name, item.cost), H)
        end
        player:printToPlayer('  Type  !shop <number>  to purchase.', H)
        return
    end

    local item = ITEMS[choice]
    if not item then
        player:printToPlayer('[Shop] Invalid choice. Type !shop to see the list.', H)
        return
    end

    if gil < item.cost then
        player:printToPlayer(
            string.format('[Shop] Not enough gil. Need %d, have %d.', item.cost, gil), H)
        return
    end

    if player:getFreeSlotsCount() == 0 then
        player:printToPlayer('[Shop] Your inventory is full!', H)
        return
    end

    player:delGil(item.cost)
    player:addItem(item.id, 1)
    player:printToPlayer(
        string.format('[Shop] Purchased %s for %d gil. Remaining balance: %d gil.',
            item.name, item.cost, gil - item.cost), H)
end

return commandObj
