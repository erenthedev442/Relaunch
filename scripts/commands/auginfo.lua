-- !auginfo  — sends augment rank + Arcane Augmenter bank balances to Windower addons.
-- Triggered automatically by AugmentBrowser / AugmentTrade on load and zone-in.
-- Format: [AUGINFO]rank=N,count=N,aff=N,hl=N,prestige=N,rebirths=N,gauntlet=N
--         [AUGBANK]p=I,n=N,itemId:qty,itemId:qty,...

---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

local function getMaxPrestigeLevel(player)
    local max = 0
    for jobId = 1, 22 do
        local lv = player:getCharVar(string.format('Prestige_Level_%d', jobId)) or 0
        if lv > max then max = lv end
    end
    return max
end

local function getTotalRebirths(player)
    local total = 0
    for jobId = 1, 22 do
        total = total + (player:getCharVar(string.format('Rebirth_Count_%d', jobId)) or 0)
    end
    return total
end

local function sendBank(player)
    local bank = require('modules/custom/lua/augment_catalyst_bank')
    local balances = bank.balances(player)
    local rows = {}
    for itemId, qty in pairs(balances) do
        itemId = tonumber(itemId)
        qty = tonumber(qty) or 0
        if itemId and qty > 0 then
            rows[#rows + 1] = { id = itemId, qty = qty }
        end
    end
    table.sort(rows, function(a, b) return a.id < b.id end)

    local S = xi.msg.channel.SYSTEM_3
    if #rows == 0 then
        player:printToPlayer('[AUGBANK]p=1,n=1', S)
        return
    end

    local chunks, cur, len = {}, {}, 0
    for _, row in ipairs(rows) do
        local token = string.format('%d:%d', row.id, row.qty)
        if #cur > 0 and (len + 1 + #token) > 160 then
            chunks[#chunks + 1] = table.concat(cur, ',')
            cur, len = { token }, #token
        else
            if #cur > 0 then
                len = len + 1
            end
            cur[#cur + 1] = token
            len = len + #token
        end
    end
    if #cur > 0 then
        chunks[#chunks + 1] = table.concat(cur, ',')
    end

    for i, body in ipairs(chunks) do
        player:printToPlayer(string.format('[AUGBANK]p=%d,n=%d,%s', i, #chunks, body), S)
    end
end

commandObj.onTrigger = function(player, _)
    local rank       = player:getCharVar('Augment_Mastery')    or 0
    local count      = player:getCharVar('Augment_Count')      or 0
    local affinities = player:getCharVar('Augment_Affinities') or 0
    local hlTier     = player:getCharVar('HL_Tier')            or 1
    local prestige   = getMaxPrestigeLevel(player)
    local rebirths   = getTotalRebirths(player)
    local gauntlet   = player:getCharVar('Gauntlet_Clears')    or 0

    player:printToPlayer(
        string.format('[AUGINFO]rank=%d,count=%d,aff=%d,hl=%d,prestige=%d,rebirths=%d,gauntlet=%d',
            rank, count, affinities, hlTier, prestige, rebirths, gauntlet),
        xi.msg.channel.SYSTEM_3
    )
    sendBank(player)
end

return commandObj
