-----------------------------------
-- Shared +4 forge recipe / trade matching.
--
-- npcUtil.tradeHasExactly rejects leftover cards (a 99-stack of Rusted ID
-- Cards vs a 60-card cost). npcUtil.tradeHas also confirmItem()s on a
-- successful probe, so the "wrong extras" path reserved the +3 piece and
-- never confirmTrade()'d -- the same reserved-count desync the 99-card
-- rollback was written to avoid.
-----------------------------------
local M = {}

M.PCARD_QTY       = 3
M.PCARD_QTY_BODY  = 6
M.RUSTED_ID       = 9538
M.RUSTED_QTY      = 60
M.RUSTED_QTY_BODY = 90
M.BLACK_ID        = 9540
M.BLACK_QTY       = 6
M.BLACK_QTY_BODY  = 12

function M.materialsFor(entry)
    local pcard  = (entry.slot == 'body') and M.PCARD_QTY_BODY  or M.PCARD_QTY
    local rusted = (entry.slot == 'body') and M.RUSTED_QTY_BODY or M.RUSTED_QTY
    local black  = (entry.slot == 'body') and M.BLACK_QTY_BODY  or M.BLACK_QTY
    return {
        { id = entry.pcard, qty = pcard,  name = 'your job\'s Paragon Card' },
        { id = M.RUSTED_ID, qty = rusted, name = 'Rusted ID Card' },
        { id = M.BLACK_ID,  qty = black,  name = 'Black ID Card' },
    }
end

function M.costString(entry)
    local parts = {}
    for _, cost in ipairs(M.materialsFor(entry)) do
        parts[#parts + 1] = string.format('%dx %s', cost.qty, cost.name)
    end
    return table.concat(parts, ', ')
end

function M.tradeQty(trade, itemId)
    if not trade or not itemId or itemId <= 0 then
        return 0
    end
    local ok, qty = pcall(function()
        return trade:getItemQty(itemId)
    end)
    return (ok and qty) or 0
end

function M.pieceOnly(trade, pieceId)
    if M.tradeQty(trade, pieceId) < 1 then
        return false
    end

    local ok, slotCount = pcall(function()
        return trade:getSlotCount()
    end)
    if not ok or not slotCount then
        return false
    end

    for slot = 0, slotCount - 1 do
        local slotOk, itemId = pcall(function()
            return trade:getItemId(slot)
        end)
        if slotOk and itemId and itemId > 0 and itemId ~= pieceId then
            return false
        end
    end

    return true
end

function M.hasRecipe(trade, pieceId, mats)
    if M.tradeQty(trade, pieceId) < 1 then
        return false
    end
    for _, cost in ipairs(mats) do
        if not cost.id or cost.id <= 0 or M.tradeQty(trade, cost.id) < cost.qty then
            return false
        end
    end
    return true
end

function M.findPlus3(trade, plus4map)
    for pieceId, entry in pairs(plus4map) do
        if M.tradeQty(trade, pieceId) >= 1 then
            return pieceId, entry
        end
    end
end

function M.classify(trade, plus4map, empyreanPlus3)
    local pieceId, entry = M.findPlus3(trade, plus4map)
    if entry then
        local mats = M.materialsFor(entry)
        if M.hasRecipe(trade, pieceId, mats) then
            return 'recipe', pieceId, entry
        end
        if M.pieceOnly(trade, pieceId) then
            return 'piece_only', pieceId, entry
        end
        return 'short', pieceId, entry
    end

    if empyreanPlus3 then
        for empyId in pairs(empyreanPlus3) do
            if M.tradeQty(trade, empyId) >= 1 then
                return 'empyrean', empyId
            end
        end
    end

    return 'none'
end

function M.confirmRecipe(trade, pieceId, mats)
    pcall(function()
        trade:confirmItem(pieceId, 1)
    end)
    for _, cost in ipairs(mats) do
        pcall(function()
            trade:confirmItem(cost.id, cost.qty)
        end)
    end
end

return M
