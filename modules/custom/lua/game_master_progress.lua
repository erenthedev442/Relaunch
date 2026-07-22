-----------------------------------
-- Shared Wave Master clear progress.
--
-- GM_Wave_Clears is an append-only bitmask: the position of each difficulty
-- in game_master_catalog.difficultyOrder is its permanent bit. Keep all gate,
-- UI, and reward code on this helper so the meanings cannot drift.
-----------------------------------
local catalog = require('modules/custom/lua/game_master_catalog')

local M = {}

M.order = catalog.difficultyOrder

function M.bitFor(difficulty)
    for index, name in ipairs(M.order) do
        if name == difficulty then
            return bit.lshift(1, index - 1)
        end
    end

    return 0
end

function M.maskThrough(count)
    return bit.lshift(1, count) - 1
end

function M.has(player, difficulty)
    local clearBit = M.bitFor(difficulty)
    return clearBit ~= 0 and
        bit.band(player:getCharVar('GM_Wave_Clears') or 0, clearBit) ~= 0
end

function M.hasThrough(player, count)
    local mask = M.maskThrough(count)
    return bit.band(player:getCharVar('GM_Wave_Clears') or 0, mask) == mask
end

function M.markClear(player, difficulty)
    local clearBit = M.bitFor(difficulty)
    if clearBit == 0 then return false end

    local clears = player:getCharVar('GM_Wave_Clears') or 0
    if bit.band(clears, clearBit) == 0 then
        player:setCharVar('GM_Wave_Clears', bit.bor(clears, clearBit))
        return true
    end

    return false
end

function M.summary(player, firstIndex, lastIndex)
    local parts = {}
    firstIndex = math.max(1, firstIndex or 1)
    lastIndex = math.min(#M.order, lastIndex or #M.order)

    for index = firstIndex, lastIndex do
        local name = M.order[index]
        parts[#parts + 1] = string.format('%s[%s]', name, M.has(player, name) and '✓' or '✗')
    end

    return table.concat(parts, '  ')
end

return M
