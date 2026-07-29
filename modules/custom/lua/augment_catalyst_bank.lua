-----------------------------------
-- Shared persistent catalyst-bank API for the Arcane Augmenter.
-----------------------------------
local catalog   = require('modules/custom/lua/augment_catalog')
local itemNames = require('modules/custom/lua/augment_item_names')

local M = {}
local S = xi.msg.channel.SYSTEM_3

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

xi.catalystBank = M

return M
