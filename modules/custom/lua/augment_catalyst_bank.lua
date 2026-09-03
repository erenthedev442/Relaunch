-----------------------------------
-- Shared persistent catalyst-bank API for the Arcane Augmenter.
-----------------------------------
local catalog   = require('modules/custom/lua/augment_catalog')
local itemNames = require('modules/custom/lua/augment_item_names')

local M = {}
local S = xi.msg.channel.SYSTEM_3

-- Former catalysts that must stay withdrawable as ordinary items after they
-- leave augment_catalog. isCatalyst stays false so Dynamis addTreasure /
-- droplist paths treat them as shared currency again.
local RETIRED_WITHDRAW =
{
    [1452] = { label = 'Ordelle Bronzepiece (currency)', cat = 7 },
}

local function readableItemName(itemId)
    local name = itemNames[itemId] or string.format('catalyst_%d', itemId)
    name = name:gsub('_', ' ')
    return name:gsub("(%a[%w']*)", function(word)
        return word:sub(1, 1):upper() .. word:sub(2)
    end)
end

function M.isCatalyst(itemId)
    return catalog[itemId] ~= nil
end

function M.isWithdrawable(itemId)
    return catalog[itemId] ~= nil or RETIRED_WITHDRAW[itemId] ~= nil
end

function M.retiredWithdrawEntries()
    local entries = {}
    for itemId, info in pairs(RETIRED_WITHDRAW) do
        table.insert(entries,
        {
            itemId = itemId,
            label  = info.label,
            cat    = info.cat,
        })
    end
    table.sort(entries, function(left, right)
        return left.itemId < right.itemId
    end)
    return entries
end

function M.itemName(itemId)
    return readableItemName(itemId)
end

function M.deposit(player, itemId, quantity, silent)
    quantity = math.floor(tonumber(quantity) or 0)
    if player == nil or not catalog[itemId] or quantity < 1 then
        return false
    end

    local ok, balance = pcall(function()
        return player:depositAugmentCatalyst(itemId, quantity)
    end)
    if not ok or type(balance) ~= 'number' or balance < quantity then
        return false
    end

    if not silent then
        player:printToPlayer(string.format(
            '[Augments] %s x%d was sent to the Arcane Augmenter. Stored balance: %d.',
            readableItemName(itemId), quantity, balance), S)
    end

    return true, balance
end

-- Called by both Lua reward paths and the engine droplist interception.
-- Returning false for a normal item tells the engine to use its treasure pool.
function M.depositDrop(player, itemId, quantity)
    return M.deposit(player, itemId, quantity or 1, false)
end

function M.balances(player)
    local ok, balances = pcall(function()
        return player:getAugmentCatalystBalances()
    end)
    return (ok and type(balances) == 'table') and balances or {}
end

function M.depositBatch(player, requests, silent)
    for _, request in ipairs(requests or {}) do
        if not catalog[request.id] or (request.qty or 0) < 1 then
            return false
        end
    end

    local ok, deposited = pcall(function()
        return player:depositAugmentCatalysts(requests)
    end)
    if not ok or deposited ~= true then
        return false
    end

    if not silent then
        local balances = M.balances(player)
        for _, request in ipairs(requests) do
            player:printToPlayer(string.format(
                '[Augments] %s x%d was sent to the Arcane Augmenter. Stored balance: %d.',
                readableItemName(request.id), request.qty, balances[request.id] or request.qty), S)
        end
    end

    return true
end

function M.consume(player, requests)
    local ok, consumed = pcall(function()
        return player:consumeAugmentCatalysts(requests)
    end)
    return ok and consumed == true
end

function M.refund(player, requests)
    return M.depositBatch(player, requests, true)
end

-- Move stored catalysts back into inventory (Dynamis currency, etc.).
-- Deducts from the bank first, then addItem; refunds the bank if the
-- inventory grant fails so balances cannot be lost.
function M.withdraw(player, itemId, quantity, silent)
    quantity = math.floor(tonumber(quantity) or 0)
    if player == nil or not M.isWithdrawable(itemId) or quantity < 1 then
        return false, 0
    end

    local have = M.balances(player)[itemId] or 0
    if have < 1 then
        return false, 0
    end

    quantity = math.min(quantity, have)
    if player:getFreeSlotsCount() < 1 then
        if not silent then
            player:printToPlayer(
                '[Arcane Bank] Inventory full — free a slot before withdrawing.', S)
        end
        return false, 0
    end

    -- Conservative room estimate: each free slot can hold one full stack (99
    -- for Dynamis currency / most catalysts). addItem failure still refunds.
    local maxCarry = player:getFreeSlotsCount() * 99
    quantity = math.min(quantity, maxCarry)
    if quantity < 1 then
        return false, 0
    end

    if not M.consume(player, { { id = itemId, qty = quantity } }) then
        if not silent then
            player:printToPlayer(
                '[Arcane Bank] Withdraw failed — stored balance changed.', S)
        end
        return false, 0
    end

    local added = player:addItem({ id = itemId, quantity = quantity })
    if not added then
        M.deposit(player, itemId, quantity, true)
        if not silent then
            player:printToPlayer(
                '[Arcane Bank] Could not place items in inventory — nothing withdrawn.', S)
        end
        return false, 0
    end

    local balance = M.balances(player)[itemId] or 0
    if not silent then
        player:printToPlayer(string.format(
            '[Arcane Bank] Withdrew %s x%d. Remaining stored: %d.',
            readableItemName(itemId), quantity, balance), S)
    end

    return true, quantity
end

xi.catalystBank = M

return M
