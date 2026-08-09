-----------------------------------
-- dynamis_bulk_exchange.lua
--
-- Retail Dynamis currency exchange only accepts exactly 10 pieces per trade
-- (CURRENCY_EXCHANGE_RATE). Exchanging thousands of singles means hundreds of
-- menu clicks. This override keeps hourglass/shop flows unchanged but allows
-- any trade quantity divisible by the exchange rate (up-conversion) or any
-- stack count (down-conversion), processed immediately on trade.
-----------------------------------
require('modules/module_utils')

local m = Module:new('dynamis_bulk_exchange')

local function exchangeRate()
    return xi.settings.main.CURRENCY_EXCHANGE_RATE
end

local function tradeOnlyItem(trade, itemId, qty)
    if trade:getGil() ~= 0 then
        return false
    end

    if trade:getItemQty(itemId) ~= qty then
        return false
    end

    return trade:getItemCount() == qty
end

local function freeSlotsForQty(qty)
    return math.ceil(qty / 99)
end

local function giveItems(player, itemId, qty, zoneId)
    -- Defensive: never hand a nil/zero item id or a non-positive quantity to the
    -- addItem binding, and never index a nil zone text table. Bail safely instead.
    local ID = zones[zoneId]
    if not itemId or itemId == 0 or not qty or qty <= 0 or not ID then
        return false
    end

    local slots = freeSlotsForQty(qty)
    if player:getFreeSlotsCount() < slots then
        player:messageSpecial(ID.text.ITEM_CANNOT_BE_OBTAINED, itemId)
        return false
    end

    local remaining = qty
    while remaining > 0 do
        local stack = math.min(remaining, 99)
        player:addItem(itemId, stack)
        remaining = remaining - stack
    end

    if qty > 1 then
        player:messageSpecial(ID.text.ITEMS_OBTAINED, itemId, qty)
    else
        player:messageSpecial(ID.text.ITEM_OBTAINED, itemId)
    end

    return true
end

local function tryBulkExchange(player, npc, trade)
    if not player:hasKeyItem(xi.ki.VIAL_OF_SHROUDED_SAND) then
        return false
    end

    local zoneId   = player:getZoneID()
    local lookup   = xi.dynamis.hourglassAndCurrencyExchangeNPCLookup[zoneId]
    if not lookup then
        return false
    end

    local currency = lookup.currency
    local rate     = exchangeRate()
    local count    = trade:getItemCount()

    -- Defensive: a malformed lookup (missing currency tiers) or a non-positive
    -- exchange rate must not reach the exchange branches below, where they would
    -- feed nil item ids / divide-by-zero into the item bindings. Fall through to
    -- the retail handler (super) instead.
    if not currency or not currency[1] or not currency[2] or not currency[3] then
        return false
    end

    if not rate or rate <= 0 then
        return false
    end

    if count <= 0 then
        return false
    end

    -- 1's -> 100's (any multiple of rate)
    if
        count >= rate and
        count % rate == 0 and
        tradeOnlyItem(trade, currency[1], count)
    then
        if giveItems(player, currency[2], count / rate, zoneId) then
            player:tradeComplete()
        end
        return true
    end

    -- 100's -> 10'000's (any multiple of rate)
    if
        count >= rate and
        count % rate == 0 and
        tradeOnlyItem(trade, currency[2], count)
    then
        if giveItems(player, currency[3], count / rate, zoneId) then
            player:tradeComplete()
        end
        return true
    end

    -- 10'000's -> 100's (each bill -> rate hundreds)
    if tradeOnlyItem(trade, currency[3], count) then
        if giveItems(player, currency[2], count * rate, zoneId) then
            player:tradeComplete()
        end
        return true
    end

    -- (optional) 100's -> 1's (each hundred -> rate singles)
    if
        xi.settings.main.ENABLE_EXCHANGE_100S_TO_1S and
        tradeOnlyItem(trade, currency[2], count)
    then
        if giveItems(player, currency[1], count * rate, zoneId) then
            player:tradeComplete()
        end
        return true
    end

    return false
end

m:addOverride('xi.dynamis.hourglassAndCurrencyExchangeNPCOnTrade', function(player, npc, trade)
    if tryBulkExchange(player, npc, trade) then
        return
    end

    super(player, npc, trade)
end)

return m
