-----------------------------------
-- Shared Abyssea Marks roster progress
--
-- The existing AbyNM_### character variables are lifetime first-clear stamps.
-- They gate only a character's first completed Empyrean weapon and also power
-- the player-facing missing-NM tracker.
-----------------------------------

local catalog = require('modules/custom/lua/abyssea_marks_catalog')

local M = {}

-- The first-Empyrean requirement was defined against the original bespoke
-- roster. Sixteen later catalog additions remain valid Marks encounters and
-- can drop forge materials, but do not move this established 136-clear target.
M.total = 136
M.groups =
{
    {
        key = 'visions',
        label = 'Visions',
        zones =
        {
            { id = xi.zone.ABYSSEA_KONSCHTAT, label = 'Konschtat', total = 15 },
            { id = xi.zone.ABYSSEA_TAHRONGI,  label = 'Tahrongi',  total = 15 },
            { id = xi.zone.ABYSSEA_LA_THEINE, label = 'La Theine', total = 15 },
        },
    },
    {
        key = 'scars',
        label = 'Scars',
        zones =
        {
            { id = xi.zone.ABYSSEA_ATTOHWA,   label = 'Attohwa',   total = 17 },
            { id = xi.zone.ABYSSEA_MISAREAUX, label = 'Misareaux', total = 16 },
            { id = xi.zone.ABYSSEA_VUNKERL,   label = 'Vunkerl',   total = 16 },
        },
    },
    {
        key = 'heroes',
        label = 'Heroes',
        zones =
        {
            { id = xi.zone.ABYSSEA_ALTEPA,     label = 'Altepa',     total = 14 },
            { id = xi.zone.ABYSSEA_GRAUBERG,   label = 'Grauberg',   total = 14 },
            { id = xi.zone.ABYSSEA_ULEGUERAND, label = 'Uleguerand', total = 14 },
        },
    },
}

M.zones = {}
M.zoneTotals = {}

local nextIndex = 1
for _, group in ipairs(M.groups) do
    for _, zone in ipairs(group.zones) do
        zone.firstIndex = nextIndex
        zone.lastIndex  = nextIndex + zone.total - 1
        nextIndex       = zone.lastIndex + 1

        M.zones[#M.zones + 1] = zone
        M.zoneTotals[zone.id] = zone.total
    end
end

assert(nextIndex - 1 == M.total and catalog.count() >= M.total, string.format(
    'Abyssea Empyrean roster covers %d entries, catalog contains %d',
    nextIndex - 1,
    catalog.count()))

function M.stampVar(index)
    return string.format('AbyNM_%03d', index)
end

function M.isCleared(player, index)
    return (player:getCharVar(M.stampVar(index)) or 0) ~= 0
end

function M.zoneProgress(player, zone)
    local cleared = 0
    for index = zone.firstIndex, zone.lastIndex do
        if M.isCleared(player, index) then
            cleared = cleared + 1
        end
    end

    return cleared, zone.total
end

function M.totalProgress(player)
    local cleared = 0
    for index = 1, M.total do
        if M.isCleared(player, index) then
            cleared = cleared + 1
        end
    end

    return cleared, M.total
end

function M.missingInZone(player, zone)
    local missing = {}
    for index = zone.firstIndex, zone.lastIndex do
        if not M.isCleared(player, index) then
            local entry = catalog.ordered[index]
            missing[#missing + 1] = entry and entry.label or string.format('Unknown NM #%d', index)
        end
    end

    return missing
end

function M.isComplete(player)
    local cleared = M.totalProgress(player)
    return cleared >= M.total
end

-- Existing characters that already completed an Empyrean final are
-- grandfathered. Everyone else completes the lifetime roster once; the final
-- weapon flag then permanently bypasses this gate for later Empyreans.
function M.firstEmpyreanGatePassed(player)
    return (player:getCharVar('WF_Empyrean_Final') or 0) == 1 or M.isComplete(player)
end

return M
