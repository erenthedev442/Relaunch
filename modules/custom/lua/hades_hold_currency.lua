-----------------------------------
-- hades_hold_currency.lua
--
-- Banked REMA / Dynamis stacks from the Hades Crate stall. Forges count
-- this hold first, then bags. Large crates never dump 100+ stacks into
-- inventory or Delivery. Players can withdraw one stack (up to 99) into
-- a free inventory slot from either Hades form.
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

-- One bag stack per click. Menu labels stay short for customMenu.
M.STACK = 99
M.LABELS =
{
    [4059] = 'Pluton',
    [4060] = 'Beitetsu',
    [4061] = 'Riftborn',
    [1450] = 'Jadeshell',
    [1451] = 'Stripeshell',
    [1453] = 'M.Silver',
    [1454] = 'R.Gold',
    [1456] = '100 Byne',
    [1457] = '10k Byne',
}

local function say(player, line)
    if not player or not player.printToPlayer then
        return
    end
    local ch = 0
    if xi and xi.msg and xi.msg.channel then
        ch = xi.msg.channel.SYSTEM_3 or 0
    end
    player:printToPlayer(line, ch)
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

function M.label(itemId)
    return M.LABELS[itemId] or ('Item ' .. tostring(itemId or 0))
end

function M.heldRows(player)
    local rows = {}
    if not player then
        return rows
    end
    for _, itemId in ipairs(M.ITEM_IDS) do
        local held = M.held(player, itemId)
        if held > 0 then
            local bags = 0
            local ok, count = pcall(function()
                return player:getItemCount(itemId)
            end)
            if ok then
                bags = count or 0
            end
            rows[#rows + 1] =
            {
                itemId = itemId,
                label  = M.label(itemId),
                held   = held,
                bags   = bags,
            }
        end
    end
    return rows
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

-- Hold only -> one inventory stack. Does not touch bags. Forges keep
-- using take() (Hold first, then bags).
function M.withdraw(player, itemId, quantity)
    quantity = math.floor(tonumber(quantity) or 0)
    if not player or not itemId or quantity < 1 then
        return false, 0
    end
    if not M.TRACKED[itemId] then
        return false, 0
    end

    local held = M.held(player, itemId)
    if held < 1 then
        say(player, '[Hades] Nothing banked for that currency.')
        return false, 0
    end

    quantity = math.min(quantity, held, M.STACK)

    local free = 0
    pcall(function()
        free = player:getFreeSlotsCount() or 0
    end)
    if free < 1 then
        say(player, '[Hades] Free an inventory slot first.')
        return false, 0
    end

    M.setHeld(player, itemId, held - quantity)

    local added = false
    pcall(function()
        added = player:addItem({ id = itemId, quantity = quantity })
    end)
    if not added then
        M.setHeld(player, itemId, M.held(player, itemId) + quantity)
        say(player, '[Hades] Could not place the stack -- nothing withdrawn.')
        return false, 0
    end

    say(player, string.format(
        '[Hades] Withdrew %s x%d. Hold remaining: %d.',
        M.label(itemId), quantity, M.held(player, itemId)))
    return true, quantity
end

return M
