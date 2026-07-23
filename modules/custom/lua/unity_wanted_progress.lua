-----------------------------------
-- Shared Unity Wanted conquest and tier-unlock helpers.
-----------------------------------
local catalog = require('modules/custom/lua/unity_wanted_catalog')

local M = {
    tierTotals = { [1] = 0, [2] = 0, [3] = 0 },
}

local nmById = {}
for _, nm in ipairs(catalog.nms) do
    nmById[nm.id] = nm
    M.tierTotals[nm.tier] = (M.tierTotals[nm.tier] or 0) + 1
end

function M.tierProgress(player, tier)
    local cleared = 0
    for _, nm in ipairs(catalog.nms) do
        if
            nm.tier == tier and
            (player:getCharVar('UW_Conq_' .. nm.id) or 0) == 1
        then
            cleared = cleared + 1
        end
    end

    return cleared, M.tierTotals[tier] or 0
end

function M.tierComplete(player, tier)
    local cleared, total = M.tierProgress(player, tier)
    return total > 0 and cleared >= total
end

function M.isTierUnlocked(player, tier)
    return tier <= 1 or M.tierComplete(player, tier - 1)
end

function M.isNmUnlocked(player, nm)
    if not M.isTierUnlocked(player, nm.tier) then
        return false
    end

    for _, nmId in ipairs(nm.prerequisites or {}) do
        if (player:getCharVar('UW_Conq_' .. nmId) or 0) ~= 1 then
            return false
        end
    end

    return true
end

function M.unlockRequirement(tier)
    if tier <= 1 then
        return nil
    end

    return string.format('conquer every Tier %d Unity Wanted NM', tier - 1)
end

function M.nmUnlockRequirement(player, nm)
    if not M.isTierUnlocked(player, nm.tier) then
        return M.unlockRequirement(nm.tier)
    end

    local missing = {}
    for _, nmId in ipairs(nm.prerequisites or {}) do
        if (player:getCharVar('UW_Conq_' .. nmId) or 0) ~= 1 then
            local required = nmById[nmId]
            missing[#missing + 1] = required and required.label or tostring(nmId)
        end
    end

    if #missing > 0 then
        return 'conquer ' .. table.concat(missing, ', ')
    end

    return nil
end

return M
