-----------------------------------
-- ExpCamp_Moogle.lua
-- Warps players to popular EXP camps
-- Zone: GM Home (zone 210)
-----------------------------------
require('modules/module_utils')
require('scripts/zones/GM_Home/Zone')
-----------------------------------
local m = Module:new('expcamp_moogle')

m:addOverride('xi.zones.GM_Home.Zone.onInitialize', function(zone)
    super(zone)

    -- NOTE: Labels are kept short on purpose. The GMTELL prompt packet (Mes)
    -- has a 150-byte payload that holds the title + every option label as
    -- quoted strings. Long labels get silently truncated, which breaks the
    -- server-side option lookup (the client sends back the truncated string
    -- and it no longer matches any option name).
    local camps =
    {
        -- Lv 10-25
        { label = '10-25 La Theine Plateau',     zone = xi.zone.LA_THEINE_PLATEAU,     x =  774.35, y =  29.00, z =  -18.57, r = 224 },
        { label = '10-25 Konschtat Highlands',   zone = xi.zone.KONSCHTAT_HIGHLANDS,   x = -223.00, y =  71.07, z =  828.00, r =  32 },
        { label = '10-25 Tahrongi Canyon',       zone = xi.zone.TAHRONGI_CANYON,       x = -160.00, y =  47.25, z =  647.11, r = 192 },
        { label = '15-30 Valkurm Dunes',         zone = xi.zone.VALKURM_DUNES,         x =  137.90, y =  -7.50, z =   97.00, r = 162 },
        -- Lv 25-45
        { label = '25-40 Qufim Island',          zone = xi.zone.QUFIM_ISLAND,          x = -251.98, y = -19.96, z =  298.21, r =  64 },
        { label = '30-45 Yuhtunga Jungle',       zone = xi.zone.YUHTUNGA_JUNGLE,       x = -239.51, y =   0.00, z = -402.77, r =  64 },
        { label = '35-50 Yhoator Jungle',        zone = xi.zone.YHOATOR_JUNGLE,        x =  197.82, y =   0.00, z =  -81.82, r = 160 },
        -- Lv 45-60
        { label = "45-60 Crawler's Nest",        zone = xi.zone.CRAWLERS_NEST,         x =  364.00, y = -32.20, z =  -22.03, r =  64 },
        { label = '45-60 Gustav Tunnel',         zone = xi.zone.GUSTAV_TUNNEL,         x =  296.68, y = -40.42, z =   64.68, r =  96 },
        { label = '50-60 Kuftal Tunnel',         zone = xi.zone.KUFTAL_TUNNEL,         x =  -16.84, y = -20.47, z = -237.00, r =   0 },
        { label = '50-60 Western Altepa Desert', zone = xi.zone.WESTERN_ALTEPA_DESERT, x =  419.33, y =  -3.12, z =   11.68, r =  32 },
        -- Lv 60-75
        { label = '60-75 The Boyahda Tree',      zone = xi.zone.THE_BOYAHDA_TREE,      x =   88.00, y = -15.00, z = -217.00, r =   0 },
        -- Lv 75-99: Aht Urhgan -> Adoulin Apex. The Aht Urhgan camps drop at the
        -- zone default (0,0,0); refine with !pos in-game for a precise spot. The
        -- Adoulin coords are verified (shared with the Warpman 'Apex Zones' tier).
        { label = '75-85 Bhaflau Thickets',      zone = xi.zone.BHAFLAU_THICKETS,      x =    0.00, y =   0.00, z =    0.00, r = 128 },
        { label = '75-85 Mount Zhayolm',         zone = xi.zone.MOUNT_ZHAYOLM,         x =    0.00, y =   0.00, z =    0.00, r = 128 },
        { label = '80-90 Caedarva Mire',         zone = xi.zone.CAEDARVA_MIRE,         x =    0.00, y =   0.00, z =    0.00, r = 128 },
        { label = '85-95 Ceizak',                zone = xi.zone.CEIZAK_BATTLEGROUNDS,  x = -107.00, y =   3.00, z =  295.00, r = 128 },
        { label = '90-99 Yorcia Weald',          zone = xi.zone.YORCIA_WEALD,          x = -420.00, y =   0.00, z =  -62.00, r =  64 },
        { label = '90-99 Marjami Ravine',        zone = xi.zone.MARJAMI_RAVINE,        x =  -23.00, y =   0.00, z =  174.00, r =   0 },
        { label = '95-99 Foret Hennetiel',       zone = xi.zone.FORET_DE_HENNETIEL,    x = -193.00, y =  -0.50, z = -252.00, r = 128 },
        { label = '95-99 Kamihr Drifts',         zone = xi.zone.KAMIHR_DRIFTS,         x =  210.00, y =  20.30, z =  315.00, r = 192 },
    }

    local PAGE_SIZE  = 4
    local totalPages = math.ceil(#camps / PAGE_SIZE)
    local menu       = { title = '', options = {} }

    local function showPage(player, page)
        local options  = {}
        local startIdx = (page - 1) * PAGE_SIZE + 1
        local endIdx   = math.min(startIdx + PAGE_SIZE - 1, #camps)

        for i = startIdx, endIdx do
            local camp = camps[i]
            table.insert(options, {
                camp.label,
                function(playerArg)
                    playerArg:printToPlayer(string.format('Warping to %s, kupo!', camp.label), xi.msg.channel.SYSTEM_3)
                    playerArg:setPos(camp.x, camp.y, camp.z, camp.r, camp.zone)
                end,
            })
        end

        if page > 1 then
            table.insert(options, {
                string.format('<< Prev (%d/%d)', page - 1, totalPages),
                function(playerArg)
                    showPage(playerArg, page - 1)
                end,
            })
        end

        if page < totalPages then
            table.insert(options, {
                string.format('Next >> (%d/%d)', page + 1, totalPages),
                function(playerArg)
                    showPage(playerArg, page + 1)
                end,
            })
        end

        table.insert(options, {
            'Never mind.',
            function(playerArg)
                playerArg:printToPlayer('Safe travels, kupo!', xi.msg.channel.SYSTEM_3)
            end,
        })

        menu.title   = string.format('Where to? (%d/%d)', page, totalPages)
        menu.options = options
        local snapshot = { title = menu.title, options = menu.options }  -- shared table + deferred send
        player:timer(30, function(p) p:customMenu(snapshot) end)
    end

    local ExpCampMoogle = zone:insertDynamicEntity({
        objtype    = xi.objType.NPC,
        name       = 'ExpCamp_Moogle',
        packetName = string.format('%sExpCamp Moogle', xi.icon.STAR_LARGE),
        look       = 2419,
        -- Teleport-services cluster (east side of GM Home), grouped with the
        -- Home Point crystal and Warpman so all the warp NPCs are together.
        x          =   0.000,
        y          =   0.000,
        z          = -15.000,
        rotation   =   128,
        widescan   =  1,

        onTrade = function(player, npc, trade)
            player:printToPlayer('No trades, kupo!', xi.msg.channel.SYSTEM_3)
        end,

        onTrigger = function(player, npc)
            showPage(player, 1)
        end,
    })
    utils.unused(ExpCampMoogle)
end)

return m
