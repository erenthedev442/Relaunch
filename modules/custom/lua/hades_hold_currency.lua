-----------------------------------
-- hades_hold_currency.lua
--
-- Banked REMA / Dynamis stacks from the Hades Crate stall. Forges count
-- this hold first, then bags. Large crates never dump 100+ stacks into
-- inventory or Delivery.
-----------------------------------
local bags = require('modules/custom/lua/hl_seal_currency')

local M = {}

M.CV_PREFIX = 'HD_Hold_'

M.ITEM_IDS =
{
    4059, -- Pluton
    4060, -- Beitetsu
    4061, -- Riftborn Boulder
    1450, -- Lungo-Nango Jadeshell
    1451, -- Rimilala Stripeshell
    1453, -- Montiont Silverpiece
    1454, -- Ranperre Goldpiece
    1456, -- 100 Byne Bill
    1457, -- 10,000 Byne Bill
}

M.TRACKED = {}
for _, itemId in ipairs(M.ITEM_IDS) do
    M.TRACKED[itemId] = true
end

function M.cv(itemId)
    return M.CV_PREFIX .. tostring(itemId)
end

function M.held(player, itemId)
    if not player or not itemId or not M.TRACKED[itemId] then
        return 0
    end
    return player:getCharVar(M.cv(itemId)) or 0
end

function M.setHeld(player, itemId, amount)
    if not player or not itemId or not M.TRACKED[itemId] then
        return false
    end
    player:setCharVar(M.cv(itemId), math.max(0, amount or 0))
    return true
end

function M.count(player, itemId)
    if not player or not itemId then
        return 0
    end
    local bagsCount = 0
    local ok, count = pcall(function()
        return player:getItemCount(itemId)
    end)
    if ok then
        bagsCount = count or 0
    end
    return M.held(player, itemId) + bagsCount
end

function M.add(player, itemId, amount)
    if not player or not itemId or not amount or amount <= 0 then
        return false
    end
    if not M.TRACKED[itemId] then
        return false
    end
    M.setHeld(player, itemId, M.held(player, itemId) + amount)
    return true
end

-- Hold first, then every bag/container stack. Restores hold if bags fail.
function M.take(player, itemId, amount)
    if not itemId or not amount or amount <= 0 then
        return true
    end
    if not player then
        return false
    end
    if M.count(player, itemId) < amount then
        return false
    end

    local held = M.held(player, itemId)
    local fromHold = math.min(held, amount)
    if fromHold > 0 then
        M.setHeld(player, itemId, held - fromHold)
    end

    local rest = amount - fromHold
    if rest <= 0 then
        return true
    end
    if bags.take(player, itemId, rest) then
        return true
    end

    if fromHold > 0 then
        M.setHeld(player, itemId, M.held(player, itemId) + fromHold)
    end
    return false
end

return M
