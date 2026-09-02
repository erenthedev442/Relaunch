-----------------------------------
-- Shared Dynamis ancient-currency exchange.
--
-- Retail (and the goblin CS) only accepts exactly CURRENCY_EXCHANGE_RATE
-- pieces. Relic grinders dump 90/99/100 stacks and get silence. This helper
-- converts floor(count / rate) in one trade and leaves the remainder.
-----------------------------------
local M = {}

function M.upgradeCounts(count, rate)
    count = tonumber(count) or 0
    rate  = tonumber(rate) or 0
    if rate <= 0 or count < rate then
        return 0, 0
    end

    local given = math.floor(count / rate)
    return given * rate, given
end

function M.isShopPrice(shop, count)
    if not shop then
        return false
    end

    for i = 1, #shop, 2 do
        if shop[i] == count then
            return true
        end
    end

    return false
end

local function tradeOnly(trade, itemId, count)
    return (trade:getGil() or 0) == 0 and trade:getItemQty(itemId) == count
end

local function giveStacks(player, itemId, qty)
    local remaining = qty
    while remaining > 0 do
        local stack = math.min(remaining, 99)
        player:addItem(itemId, stack)
        remaining = remaining - stack
    end
end

local function completeUpgrade(player, trade, fromId, toId, taken, given)
    local zoneId = player:getZoneID()
    local ID     = zones[zoneId]
    local slots  = math.ceil(given / 99)

    if not ID or not toId or given <= 0 then
        return false
    end

    if player:getFreeSlotsCount() < slots then
        player:messageSpecial(ID.text.ITEM_CANNOT_BE_OBTAINED, toId)
        player:printToPlayer(
            '[Dynamis] Free an inventory slot and trade again.',
            xi.msg.channel.SYSTEM_3)
        return true
    end

    trade:confirmItem(fromId, taken)
    player:confirmTrade()
    giveStacks(player, toId, given)

    if given > 1 then
        player:messageSpecial(ID.text.ITEMS_OBTAINED, toId, given)
    else
        player:messageSpecial(ID.text.ITEM_OBTAINED, toId)
    end

    player:printToPlayer(
        string.format('[Dynamis] Exchanged %d for %d.', taken, given),
        xi.msg.channel.SYSTEM_3)
    return true
end

-- Returns true when this trade was a currency exchange (success or a
-- told-the-player failure). False means the retail hourglass/shop path
-- should run.
function M.tryExchange(player, _, trade)
    if not player:hasKeyItem(xi.ki.VIAL_OF_SHROUDED_SAND) then
        return false
    end

    local zoneId = player:getZoneID()
    local lookup = xi.dynamis.hourglassAndCurrencyExchangeNPCLookup[zoneId]
    if not lookup or not lookup.currency then
        return false
    end

    local currency = lookup.currency
    local rate     = xi.settings.main.CURRENCY_EXCHANGE_RATE
    local count    = trade:getItemCount()

    if not currency[1] or not currency[2] or not currency[3] then
        return false
    end

    if not rate or rate <= 0 or not count or count <= 0 then
        return false
    end

    -- Singles -> hundreds (90, 99, 100, 792, ...)
    if tradeOnly(trade, currency[1], count) then
        local taken, given = M.upgradeCounts(count, rate)
        if given <= 0 then
            player:printToPlayer(
                string.format('[Dynamis] Trade at least %d of the same ancient currency.', rate),
                xi.msg.channel.SYSTEM_3)
            return true
        end

        return completeUpgrade(player, trade, currency[1], currency[2], taken, given)
    end

    -- Hundreds -> 10,000s. Skip amounts the goblin shop also charges so a
    -- 20x 100-Byne trade still buys Marksman's Oil instead of becoming 2x 10k.
    if
        tradeOnly(trade, currency[2], count) and
        not M.isShopPrice(lookup.shop, count)
    then
        local taken, given = M.upgradeCounts(count, rate)
        if given > 0 then
            return completeUpgrade(player, trade, currency[2], currency[3], taken, given)
        end
    end

    -- 10,000s -> hundreds (any number of bills)
    if tradeOnly(trade, currency[3], count) then
        return completeUpgrade(player, trade, currency[3], currency[2], count, count * rate)
    end

    return false
end

return M
