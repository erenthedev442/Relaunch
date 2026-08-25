-----------------------------------
-- !warp
-- Categorized player travel menu. Direct QoL commands remain available for
-- players who prefer them; this provides a discoverable central entry point.
-----------------------------------
---@type TCommand
local commandObj = {}

commandObj.cmdprops =
{
    permission = 0,
    parameters = '',
}

local SYS = xi.msg.channel.SYSTEM_3

local showRoot
local showActivities
local showAscensionAltars
local showSpecializedTravel

local function openMenu(player, title, options)
    player:timer(30, function(p)
        p:customMenu({
            title = title,
            options = options,
        })
    end)
end

local function runCommand(player, path, ...)
    local ok, command = pcall(require, path)
    if not ok or not command or not command.onTrigger then
        player:printToPlayer('[Warp] That destination is temporarily unavailable.', SYS)
        return
    end

    command.onTrigger(player, ...)
end

local function warp(player, label, zone, x, y, z, rot)
    player:printToPlayer(string.format('[Warp] Traveling to %s.', label), SYS)
    player:setPos(x, y, z, rot or 0, zone)
end

local huntDestinations =
{
    { 'Hunting League Hub', xi.zone.ESCHA_ZITAH, 0.0000, -0.5000, -30.0000, 128 },
    { 'Tier 1 Hunt Cluster', xi.zone.ESCHA_ZITAH, -41.5941, 0.1103, 73.7704, 176 },
    { 'Tier 2 Hunt Cluster', xi.zone.ESCHA_ZITAH, 40.9101, 0.4831, 132.8770, 71 },
    { 'Tier 3 Hunt Cluster', xi.zone.ESCHA_ZITAH, 48.6277, 0.8776, 18.8663, 215 },
    { 'Tier 4 Hunt Cluster', xi.zone.ESCHA_ZITAH, 22.0112, 0.8983, -121.4367, 126 },
    { 'Tier 5 Hunt Cluster', xi.zone.ESCHA_ZITAH, 433.8451, 0.1066, -199.3157, 119 },
}

local expCamps =
{
    { '10-25 La Theine',      xi.zone.LA_THEINE_PLATEAU,      774.35,  29.00,  -18.57, 224 },
    { '10-25 Konschtat',      xi.zone.KONSCHTAT_HIGHLANDS,   -223.00,  71.07,  828.00,  32 },
    { '10-25 Tahrongi',       xi.zone.TAHRONGI_CANYON,       -160.00,  47.25,  647.11, 192 },
    { '15-30 Valkurm',        xi.zone.VALKURM_DUNES,          137.90,  -7.50,   97.00, 162 },
    { '25-40 Qufim',          xi.zone.QUFIM_ISLAND,          -251.98, -19.96,  298.21,  64 },
    { '30-45 Yuhtunga',       xi.zone.YUHTUNGA_JUNGLE,       -239.51,   0.00, -402.77,  64 },
    { '35-50 Yhoator',        xi.zone.YHOATOR_JUNGLE,         197.82,   0.00,  -81.82, 160 },
    { "45-60 Crawler's Nest", xi.zone.CRAWLERS_NEST,          364.00, -32.20,  -22.03,  64 },
    { '45-60 Gustav',         xi.zone.GUSTAV_TUNNEL,          296.68, -40.42,   64.68,  96 },
    { '50-60 Kuftal',         xi.zone.KUFTAL_TUNNEL,          -16.84, -20.47, -237.00,   0 },
    { '50-60 W. Altepa',      xi.zone.WESTERN_ALTEPA_DESERT,  419.33,  -3.12,   11.68,  32 },
    { '60-75 Boyahda Tree',   xi.zone.THE_BOYAHDA_TREE,        88.00, -15.00, -217.00,   0 },
    { '75-85 Bhaflau',        xi.zone.BHAFLAU_THICKETS,         0.00,   0.00,    0.00, 128 },
    { '75-85 Mount Zhayolm',  xi.zone.MOUNT_ZHAYOLM,          658.48, -27.4748, 314.4547, 102 },
    { '80-85 Misareaux',      xi.zone.MISAREAUX_COAST,        488.4478, -22.1281, 260.9005, 180 },
    { '80-90 Caedarva',       xi.zone.CAEDARVA_MIRE,          282.7048, -4.1514, -703.4025, 153 },
    { '85-95 Ceizak',         xi.zone.CEIZAK_BATTLEGROUNDS,   332.8839, 0.3897, 136.2704, 69 },
    { '90-99 Yorcia',         xi.zone.YORCIA_WEALD,          -183.76,   1.54,   69.93,  29 },
    { '90-99 Marjami',        xi.zone.MARJAMI_RAVINE,         367.30, -59.27,  145.73,  36 },
    { '90-99 N. Gustaberg S', xi.zone.NORTH_GUSTABERG_S,     -547.5531, 39.7761, 434.5975, 117 },
    { '95-99 Foret',          xi.zone.FORET_DE_HENNETIEL,    -420.14,  -6.17,  181.50, 249 },
    { '95-99 Kamihr',         xi.zone.KAMIHR_DRIFTS,          210.00,  20.30,  315.00, 192 },
}

local function showHunts(player)
    local options = {}
    for _, destination in ipairs(huntDestinations) do
        local dest = destination
        options[#options + 1] =
        {
            dest[1],
            function(p)
                warp(p, dest[1], dest[2], dest[3], dest[4], dest[5], dest[6])
            end,
        }
    end
    options[#options + 1] = { 'Back', function(p) showRoot(p) end }
    openMenu(player, 'Hunting League Travel', options)
end

local function showExpCamps(player, page)
    local pageSize = 4
    local pages = math.ceil(#expCamps / pageSize)
    page = math.max(1, math.min(page or 1, pages))

    local options = {}
    local first = (page - 1) * pageSize + 1
    local last = math.min(#expCamps, first + pageSize - 1)
    for index = first, last do
        local camp = expCamps[index]
        options[#options + 1] =
        {
            camp[1],
            function(p)
                warp(p, camp[1], camp[2], camp[3], camp[4], camp[5], camp[6])
            end,
        }
    end
    if page < pages then
        options[#options + 1] = { 'Next >>', function(p) showExpCamps(p, page + 1) end }
    end
    if page > 1 then
        options[#options + 1] = { '<< Previous', function(p) showExpCamps(p, page - 1) end }
    end
    options[#options + 1] = { 'Back', function(p) showRoot(p) end }
    openMenu(player, string.format('EXP Camps (%d/%d)', page, pages), options)
end

local function showCapacity(player)
    openMenu(player, 'Capacity Point Camps', {
        {
            'Bibiki Bay',
            function(p)
                if p:getMainLvl() < 99 then
                    p:printToPlayer('Capacity Point camps require a level 99 main job.', SYS)
                    return
                end
                warp(p, 'Bibiki Bay Capacity Camp', xi.zone.BIBIKI_BAY, 93.0, -45.5, 928.0, 128)
            end,
        },
        {
            "King Ranperre's Tomb",
            function(p)
                if p:getMainLvl() < 99 then
                    p:printToPlayer('Capacity Point camps require a level 99 main job.', SYS)
                    return
                end
                warp(p, "King Ranperre's Tomb Capacity Camp",
                    xi.zone.KING_RANPERRES_TOMB, -54.55, 7.21, 82.03, 0)
            end,
        },
        { 'Back', function(p) showRoot(p) end },
    })
end

local function unityDestinations()
    local catalog = require('modules/custom/lua/unity_wanted_catalog')
    local junctionMap = require('modules/custom/lua/unity_junction_map')
    local destinations = {}

    for _, nm in ipairs(catalog.nms) do
        local zoneId = junctionMap.byNm[nm.name]
        local junction = zoneId and junctionMap.junctions[zoneId]
        if junction and junction.points and junction.points[1] then
            destinations[#destinations + 1] =
            {
                label = nm.label or nm.name,
                tier = nm.tier or 0,
                zone = zoneId,
                point = junction.points[1],
            }
        end
    end

    table.sort(destinations, function(a, b)
        if a.tier ~= b.tier then
            return a.tier < b.tier
        end
        return a.label < b.label
    end)

    return destinations
end

local function showUnity(player, page)
    local destinations = unityDestinations()
    local pageSize = 4
    local pages = math.max(1, math.ceil(#destinations / pageSize))
    page = math.max(1, math.min(page or 1, pages))

    local options = {}
    local first = (page - 1) * pageSize + 1
    local last = math.min(#destinations, first + pageSize - 1)
    for index = first, last do
        local destination = destinations[index]
        options[#options + 1] =
        {
            string.format('[T%d] %s', destination.tier, destination.label),
            function(p)
                local point = destination.point
                warp(p, destination.label, destination.zone,
                    point.x + 1.5, point.y, point.z + 1.5, point.rot or 0)
            end,
        }
    end
    if page < pages then
        options[#options + 1] = { 'Next >>', function(p) showUnity(p, page + 1) end }
    end
    if page > 1 then
        options[#options + 1] = { '<< Previous', function(p) showUnity(p, page - 1) end }
    end
    options[#options + 1] = { 'Back', function(p) showActivities(p) end }
    openMenu(player, string.format('Unity Wanted (%d/%d)', page, pages), options)
end

local function showWaveMasters(player)
    local catalog = require('modules/custom/lua/game_master_catalog')
    local options = {}
    for index, point in ipairs(catalog.npcPositions or {}) do
        local spot = point
        local number = index
        options[#options + 1] =
        {
            string.format('Wave Master %d', number),
            function(p)
                warp(p, string.format('Wave Master %d', number), catalog.npcPos.zoneId,
                    spot.x, spot.y, spot.z, spot.rot or 0)
            end,
        }
    end
    options[#options + 1] = { 'Back', function(p) showActivities(p) end }
    openMenu(player, 'Wave Master Arenas', options)
end

local function showBattlefields(player)
    openMenu(player, 'Battlefield Travel', {
        {
            'HTBF Entrance',
            function(p)
                runCommand(p, 'modules/custom/commands/htbf')
            end,
        },
        {
            "Maat's Echo",
            function(p)
                warp(p, "Maat's Echo", xi.zone.RULUDE_GARDENS, 12.0, 3.0, 118.0, 128)
            end,
        },
        {
            'The Voidspire',
            function(p)
                warp(p, 'The Voidspire', xi.zone.ESCHA_RUAUN, 2.0, -34.0, -463.0, 128)
            end,
        },
        { 'Back', function(p) showActivities(p) end },
    })
end

showAscensionAltars = function(player)
    openMenu(player, 'Provenance: Ascension Altars', {
        {
            'Ascension Altar I',
            function(p)
                runCommand(p, 'modules/custom/commands/prov1')
            end,
        },
        {
            'Ascension Altar II',
            function(p)
                runCommand(p, 'modules/custom/commands/prov2')
            end,
        },
        {
            'Ascension Altar III',
            function(p)
                runCommand(p, 'modules/custom/commands/prov3')
            end,
        },
        { 'Back', function(p) showActivities(p) end },
    })
end

showSpecializedTravel = function(player)
    openMenu(player, 'Specialized Travel', {
        {
            'Augment Catalysts',
            function(p)
                runCommand(p, 'modules/custom/commands/augwarp')
            end,
        },
        {
            'Affinity NMs',
            function(p)
                runCommand(p, 'modules/custom/commands/affinitynm')
            end,
        },
        {
            "Hunters' Guild NMs",
            function(p)
                runCommand(p, 'modules/custom/commands/huntwarp')
            end,
        },
        {
            'Saved Waypoints',
            function(p)
                runCommand(p, 'modules/custom/commands/waypoint')
            end,
        },
        {
            'Legacy Reisenjima Henge',
            function(p)
                runCommand(p, 'modules/custom/commands/henge')
            end,
        },
        {
            'Leafallia Hub',
            function(p)
                runCommand(p, 'modules/custom/commands/leaf')
            end,
        },
        { 'Back', function(p) showActivities(p) end },
    })
end

local function showProgressionHubs(player)
    openMenu(player, 'Progression Hubs', {
        {
            'Job Rebirth',
            function(p)
                runCommand(p, 'scripts/commands/rebirth')
            end,
        },
        {
            'Reforge Armor',
            function(p)
                runCommand(p, 'scripts/commands/reforged')
            end,
        },
        { 'Back', function(p) showActivities(p) end },
    })
end

showActivities = function(player)
    openMenu(player, 'Activity Travel', {
        {
            'Battlefields',
            function(p)
                showBattlefields(p)
            end,
        },
        {
            'Progression Hubs',
            function(p)
                showProgressionHubs(p)
            end,
        },
        {
            'Unity Wanted',
            function(p)
                showUnity(p, 1)
            end,
        },
        {
            'Domain Invasion',
            function(p)
                runCommand(p, 'modules/custom/commands/diwarp')
            end,
        },
        {
            'Wave Masters',
            function(p)
                showWaveMasters(p)
            end,
        },
        {
            'Ascension Altars',
            function(p)
                showAscensionAltars(p)
            end,
        },
        {
            'Specialized Travel',
            function(p)
                showSpecializedTravel(p)
            end,
        },
        { 'Back', function(p) showRoot(p) end },
    })
end

showRoot = function(player)
    openMenu(player, 'Relaunch Travel', {
        {
            'Hub',
            function(p)
                warp(p, 'Relaunch Hub', xi.zone.ABDHALJS_ISLE_PURGONORGO,
                    571.5259, -3.3592, 508.8601, 65)
            end,
        },
        {
            'Home Point',
            function(p)
                p:warp()
            end,
        },
        { 'Hunting League', function(p) showHunts(p) end },
        { 'EXP Camps', function(p) showExpCamps(p, 1) end },
        { 'Capacity Camps', function(p) showCapacity(p) end },
        { 'Activities', function(p) showActivities(p) end },
        { 'Close', function() end },
    })
end

commandObj.onTrigger = function(player)
    showRoot(player)
end

return commandObj
