-----------------------------------
-- !empyaby
--
-- Tracks the lifetime 136-NM Abyssea Marks roster required for a character's
-- first completed Empyrean weapon. Progress is grouped by expansion and zone;
-- missing NM names are paged to stay within the custom-menu option limit.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

local progress = require('modules/custom/lua/abyssea_marks_progress')
local PAGE_SIZE = 5

local showRoot
local showGroup
local showZone

showZone = function(player, group, zone, page)
    local missing = progress.missingInZone(player, zone)
    local cleared, total = progress.zoneProgress(player, zone)
    local pages = math.max(1, math.ceil(#missing / PAGE_SIZE))
    page = math.max(1, math.min(page or 1, pages))

    local options = {}
    if #missing == 0 then
        options[#options + 1] = { 'All NMs cleared!', function(p) showGroup(p, group) end }
    else
        local first = (page - 1) * PAGE_SIZE + 1
        local last  = math.min(#missing, first + PAGE_SIZE - 1)
        for index = first, last do
            local nmName = missing[index]
            options[#options + 1] =
            {
                nmName,
                function(p)
                    p:printToPlayer(
                        string.format('[Empyrean Roster] Missing in %s: %s.', zone.label, nmName),
                        xi.msg.channel.SYSTEM_3)
                    showZone(p, group, zone, page)
                end,
            }
        end
    end

    if page < pages then
        options[#options + 1] = { 'Next >>', function(p) showZone(p, group, zone, page + 1) end }
    end
    if page > 1 then
        options[#options + 1] = { '<< Previous', function(p) showZone(p, group, zone, page - 1) end }
    end
    options[#options + 1] = { 'Back', function(p) showGroup(p, group) end }

    player:timer(30, function(p)
        p:customMenu({
            title = string.format('%s: %d/%d (missing %d) [%d/%d]',
                zone.label, cleared, total, #missing, page, pages),
            options = options,
        })
    end)
end

showGroup = function(player, group)
    local options = {}
    for _, zone in ipairs(group.zones) do
        local zoneRef = zone
        local cleared, total = progress.zoneProgress(player, zoneRef)
        options[#options + 1] =
        {
            string.format('%s: %d/%d', zoneRef.label, cleared, total),
            function(p) showZone(p, group, zoneRef, 1) end,
        }
    end
    options[#options + 1] = { 'Back', function(p) showRoot(p) end }

    player:timer(30, function(p)
        p:customMenu({
            title = group.label .. ' Abyssea roster',
            options = options,
        })
    end)
end

showRoot = function(player)
    local cleared, total = progress.totalProgress(player)
    local bypassed = (player:getCharVar('WF_Empyrean_Final') or 0) == 1
    local options = {}

    for _, group in ipairs(progress.groups) do
        local groupRef = group
        options[#options + 1] =
        {
            groupRef.label,
            function(p) showGroup(p, groupRef) end,
        }
    end
    options[#options + 1] = { 'Close', function() end }

    player:printToPlayer(
        bypassed and
            '[Empyrean Roster] First Empyrean already completed; later Empyreans do not require this roster.' or
            string.format('[Empyrean Roster] First-Empyrean progress: %d/%d.', cleared, total),
        xi.msg.channel.SYSTEM_3)

    player:timer(30, function(p)
        p:customMenu({
            title = string.format('Empyrean Abyssea: %d/%d%s',
                cleared, total, bypassed and ' (bypassed)' or ''),
            options = options,
        })
    end)
end

commandObj.onTrigger = function(player)
    showRoot(player)
end

return commandObj
