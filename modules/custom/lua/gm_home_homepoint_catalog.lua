-----------------------------------
-- gm_home_homepoint_catalog.lua
--
-- Destinations for the GM Home Home Point crystal's "Warp to a home point"
-- menu. Every real homepoint in the game is listed here so the crystal can
-- act like a full homepoint network -- warp anywhere, FREE, with no
-- attunement requirement.
--
-- WHY THIS FILE EXISTS (it duplicates upstream data on purpose):
--   The canonical destination table lives in scripts/globals/homepoint.lua as
--   a FILE-LOCAL upvalue `homepointData` -- it is never exposed on
--   xi.homepoint, so another module cannot read it without editing that
--   upstream file. Project rule: custom code lives entirely under
--   modules/custom/ and never edits src/ or scripts/ (so LandSandBoat
--   upstream pulls don't clobber it). So we copy the coordinates here.
--   If upstream ever adds/moves a homepoint, re-sync this file by hand.
--
-- Each dest mirrors homepointData's `dest = { x, y, z, rot, zone }`, stored as
--   { label, zone, x, y, z, r }  (label + the same fields gil_warp uses).
-- The warp is a plain player:setPos(x, y, z, r, zone) -- no cost, no gating.
--
-- EXCLUDED on purpose:
--   * Index 122 (GM Home itself)  -- no point warping to where you are.
--   * Index  67 (Al Zahbi)        -- upstream flags it "DOESN'T CURRENTLY
--                                    EXIST" with a 0,0,0 dest; would dump the
--                                    player at the origin.
--
-- Regions are sized for humans, not for the packet cap -- the module
-- paginates each region automatically, so a region can hold any number of
-- destinations. The big "Dungeons & Fields" bucket is alphabetized so a zone
-- is easy to find across pages.
-----------------------------------
local catalog = {}

catalog.regions =
{
    {
        name  = "San d'Oria",
        dests =
        {
            { label = 'Southern 1', zone = xi.zone.SOUTHERN_SAN_DORIA, x =  -85.554, y =    1.0, z = -64.554, r =  45 }, -- hp 0
            { label = 'Southern 2', zone = xi.zone.SOUTHERN_SAN_DORIA, x =    44.1,  y =    2.0, z =  -34.5,  r = 170 }, -- hp 1
            { label = 'Southern 3', zone = xi.zone.SOUTHERN_SAN_DORIA, x =   140.5,  y =   -2.0, z =  121.0,  r =   0 }, -- hp 2
            { label = 'Southern 4', zone = xi.zone.SOUTHERN_SAN_DORIA, x =  -165.0,  y =   -1.0, z =   12.0,  r =  65 }, -- hp 97
            { label = 'Northern 1', zone = xi.zone.NORTHERN_SAN_DORIA, x =  -178.0,  y =    4.0, z =   71.0,  r =   0 }, -- hp 3
            { label = 'Northern 2', zone = xi.zone.NORTHERN_SAN_DORIA, x =    10.0,  y =   -0.2, z =   95.0,  r =   0 }, -- hp 4
            { label = 'Northern 3', zone = xi.zone.NORTHERN_SAN_DORIA, x =    70.0,  y =   -0.2, z =   10.0,  r =   0 }, -- hp 5
            { label = 'Northern 4', zone = xi.zone.NORTHERN_SAN_DORIA, x =  -132.0,  y =   12.0, z =  194.0,  r = 170 }, -- hp 98
            { label = 'Port 1',     zone = xi.zone.PORT_SAN_DORIA,     x =   -38.0,  y =   -4.0, z =  -63.0,  r =   0 }, -- hp 6
            { label = 'Port 2',     zone = xi.zone.PORT_SAN_DORIA,     x =    48.0,  y =  -12.0, z = -105.0,  r =   0 }, -- hp 7
            { label = 'Port 3',     zone = xi.zone.PORT_SAN_DORIA,     x =    -6.0,  y =  -13.0, z = -150.0,  r =   0 }, -- hp 8
        },
    },
    {
        name  = 'Bastok',
        dests =
        {
            { label = 'Mines 1',      zone = xi.zone.BASTOK_MINES,   x =   39.0, y =   0.0, z =  -43.0, r =   0 }, -- hp 9
            { label = 'Mines 2',      zone = xi.zone.BASTOK_MINES,   x =  118.0, y =   1.0, z =  -58.0, r =   0 }, -- hp 10
            { label = 'Mines 3',      zone = xi.zone.BASTOK_MINES,   x =   87.0, y =   7.0, z =    1.0, r =   0 }, -- hp 99
            { label = 'Markets 1',    zone = xi.zone.BASTOK_MARKETS, x = -342.0, y = -10.0, z = -154.0, r =   0 }, -- hp 11
            { label = 'Markets 2',    zone = xi.zone.BASTOK_MARKETS, x = -328.0, y = -12.0, z =  -33.0, r =   0 }, -- hp 12
            { label = 'Markets 3',    zone = xi.zone.BASTOK_MARKETS, x = -189.0, y =  -8.0, z =   26.0, r =   0 }, -- hp 13
            { label = 'Markets 4',    zone = xi.zone.BASTOK_MARKETS, x = -192.0, y =  -6.0, z =  -69.0, r =   0 }, -- hp 100
            { label = 'Port 1',       zone = xi.zone.PORT_BASTOK,    x =  124.0, y =   8.0, z =    7.0, r =   0 }, -- hp 14
            { label = 'Port 2',       zone = xi.zone.PORT_BASTOK,    x =   42.0, y =   8.5, z = -244.0, r =   0 }, -- hp 15
            { label = 'Port 3',       zone = xi.zone.PORT_BASTOK,    x = -127.0, y =  -6.0, z =    8.0, r = 206 }, -- hp 101
            { label = 'Metalworks 1', zone = xi.zone.METALWORKS,     x =   46.0, y = -14.0, z =  -19.0, r =   0 }, -- hp 16
            { label = 'Metalworks 2', zone = xi.zone.METALWORKS,     x =  -76.0, y =   2.0, z =    3.0, r = 124 }, -- hp 102
        },
    },
    {
        name  = 'Windurst',
        dests =
        {
            { label = 'Waters 1', zone = xi.zone.WINDURST_WATERS, x =  -32.0, y = -5.0, z =  132.0, r =   0 }, -- hp 17
            { label = 'Waters 2', zone = xi.zone.WINDURST_WATERS, x =  138.5, y =  0.0, z =  -14.0, r =   0 }, -- hp 18
            { label = 'Waters 3', zone = xi.zone.WINDURST_WATERS, x =    5.0, y = -4.0, z = -175.0, r = 130 }, -- hp 103
            { label = 'Waters 4', zone = xi.zone.WINDURST_WATERS, x =  -92.0, y = -2.0, z =   54.0, r = 155 }, -- hp 118
            { label = 'Walls 1',  zone = xi.zone.WINDURST_WALLS,  x =  -72.0, y = -5.0, z =  125.0, r =   0 }, -- hp 19
            { label = 'Walls 2',  zone = xi.zone.WINDURST_WALLS,  x = -212.0, y =  0.0, z =  -99.0, r =   0 }, -- hp 20
            { label = 'Walls 3',  zone = xi.zone.WINDURST_WALLS,  x =   31.0, y = -6.5, z =  -40.0, r =   0 }, -- hp 21
            { label = 'Port 1',   zone = xi.zone.PORT_WINDURST,   x = -188.0, y = -4.0, z =  101.0, r =   0 }, -- hp 22
            { label = 'Port 2',   zone = xi.zone.PORT_WINDURST,   x = -207.0, y = -8.0, z =  210.0, r =   0 }, -- hp 23
            { label = 'Port 3',   zone = xi.zone.PORT_WINDURST,   x =  180.0, y = -12.0, z = 226.0, r =   0 }, -- hp 24
            { label = 'Woods 1',  zone = xi.zone.WINDURST_WOODS,  x =    9.0, y = -2.0, z =    0.0, r =   0 }, -- hp 25
            { label = 'Woods 2',  zone = xi.zone.WINDURST_WOODS,  x =  107.0, y = -5.0, z =  -56.0, r =   0 }, -- hp 26
            { label = 'Woods 3',  zone = xi.zone.WINDURST_WOODS,  x =  -92.0, y = -5.0, z =   62.0, r =   0 }, -- hp 27
            { label = 'Woods 4',  zone = xi.zone.WINDURST_WOODS,  x =   74.0, y = -7.0, z = -139.0, r =   0 }, -- hp 28
            { label = 'Woods 5',  zone = xi.zone.WINDURST_WOODS,  x =  -43.5, y =  0.0, z = -145.0, r =   0 }, -- hp 119
        },
    },
    {
        name  = 'Jeuno',
        dests =
        {
            { label = "Ru'Lude 1", zone = xi.zone.RULUDE_GARDENS, x =  -6.0, y =  3.0, z =    0.0, r =   0 }, -- hp 29
            { label = "Ru'Lude 2", zone = xi.zone.RULUDE_GARDENS, x =  53.0, y =  9.0, z =  -57.0, r =   0 }, -- hp 30
            { label = "Ru'Lude 3", zone = xi.zone.RULUDE_GARDENS, x = -67.0, y =  6.0, z =  -25.0, r =   1 }, -- hp 31
            { label = 'Upper 1',   zone = xi.zone.UPPER_JEUNO,    x = -99.0, y =  0.0, z =  167.0, r =   0 }, -- hp 32
            { label = 'Upper 2',   zone = xi.zone.UPPER_JEUNO,    x =  32.0, y = -1.0, z =  -44.0, r =   0 }, -- hp 33
            { label = 'Upper 3',   zone = xi.zone.UPPER_JEUNO,    x = -52.0, y =  1.0, z =   16.0, r =   0 }, -- hp 34
            { label = 'Lower 1',   zone = xi.zone.LOWER_JEUNO,    x = -99.0, y =  0.0, z = -183.0, r =   0 }, -- hp 35
            { label = 'Lower 2',   zone = xi.zone.LOWER_JEUNO,    x =  18.0, y = -1.0, z =   54.0, r =   0 }, -- hp 36
            { label = 'Port 1',    zone = xi.zone.PORT_JEUNO,     x =  37.0, y =  0.0, z =    9.0, r =   0 }, -- hp 37
            { label = 'Port 2',    zone = xi.zone.PORT_JEUNO,     x = -155.0, y = -1.0, z =  -4.0, r =   0 }, -- hp 38
        },
    },
    {
        name  = 'Aht Urhgan',
        dests =
        {
            { label = 'Whitegate 1', zone = xi.zone.AHT_URHGAN_WHITEGATE, x =  -21.0, y =  0.0, z =  -21.0, r =   0 }, -- hp 65
            { label = 'Whitegate 2', zone = xi.zone.AHT_URHGAN_WHITEGATE, x =  130.0, y =  0.0, z =  -16.0, r =   0 }, -- hp 106
            { label = 'Whitegate 3', zone = xi.zone.AHT_URHGAN_WHITEGATE, x = -108.0, y = -6.0, z =  108.0, r = 192 }, -- hp 107
            { label = 'Whitegate 4', zone = xi.zone.AHT_URHGAN_WHITEGATE, x =  -99.0, y =  0.0, z =  -68.0, r =   0 }, -- hp 108
            { label = 'Nashmau',     zone = xi.zone.NASHMAU,              x =  -20.0, y =  0.0, z =  -25.0, r =   0 }, -- hp 66
        },
    },
    {
        name  = 'Adoulin',
        dests =
        {
            { label = 'W.Adoulin 1', zone = xi.zone.WESTERN_ADOULIN, x = -84.0, y = 4.0, z =  -32.0, r = 128 }, -- hp 44
            { label = 'W.Adoulin 2', zone = xi.zone.WESTERN_ADOULIN, x =  32.0, y = 0.0, z = -164.0, r =  32 }, -- hp 109
            { label = 'E.Adoulin 1', zone = xi.zone.EASTERN_ADOULIN, x = -51.0, y = 0.0, z =   59.0, r = 128 }, -- hp 45
            { label = 'E.Adoulin 2', zone = xi.zone.EASTERN_ADOULIN, x = -51.0, y = 0.0, z =  -96.0, r =  96 }, -- hp 110
        },
    },
    {
        name  = 'Ulbuka',
        dests =
        {
            { label = 'Ceizak',          zone = xi.zone.CEIZAK_BATTLEGROUNDS,  x = -107.0, y =   3.0,  z =  295.0, r = 128 }, -- hp 46
            { label = 'Foret Hennetiel', zone = xi.zone.FORET_DE_HENNETIEL,    x = -193.0, y =  -0.5,  z = -252.0, r = 128 }, -- hp 47
            { label = 'Morimar Basalt',  zone = xi.zone.MORIMAR_BASALT_FIELDS, x = -415.0, y = -63.2,  z =  409.0, r = 106 }, -- hp 48
            { label = 'Yorcia Weald',    zone = xi.zone.YORCIA_WEALD,          x = -420.0, y =   0.0,  z =  -62.0, r =  64 }, -- hp 49
            { label = 'Marjami Ravine',  zone = xi.zone.MARJAMI_RAVINE,        x =  -23.0, y =   0.0,  z =  174.0, r =   0 }, -- hp 50
            { label = 'Kamihr Drifts',   zone = xi.zone.KAMIHR_DRIFTS,         x =  210.0, y =  20.299, z = 315.0, r = 192 }, -- hp 51
            { label = "Ra'Kaznar Court", zone = xi.zone.RAKAZNAR_INNER_COURT,  x =  757.0, y = 120.0,  z =   17.5, r = 128 }, -- hp 116
        },
    },
    {
        name  = 'Other Towns',
        dests =
        {
            { label = 'Kazham',     zone = xi.zone.KAZHAM,             x =  78.0,  y = -13.0,    z =  -94.0, r =   0 }, -- hp 39
            { label = 'Mhaura',     zone = xi.zone.MHAURA,             x = -13.0,  y = -15.0,    z =   87.0, r =   0 }, -- hp 40
            { label = 'Selbina',    zone = xi.zone.SELBINA,            x =  36.0,  y = -11.0,    z =   35.0, r =   0 }, -- hp 43
            { label = 'Norg 1',     zone = xi.zone.NORG,               x = -27.0,  y =   0.0,    z =  -47.0, r =   0 }, -- hp 41
            { label = 'Norg 2',     zone = xi.zone.NORG,               x = -65.0,  y =  -5.0,    z =   54.0, r = 127 }, -- hp 104
            { label = 'Rabao 1',    zone = xi.zone.RABAO,              x = -29.0,  y =   0.0,    z =  -76.0, r =   0 }, -- hp 42
            { label = 'Rabao 2',    zone = xi.zone.RABAO,              x = -21.0,  y =   8.0,    z =  110.0, r =  64 }, -- hp 105
            { label = 'Tavnazia 1', zone = xi.zone.TAVNAZIAN_SAFEHOLD, x =  -1.0,  y = -28.0,    z =  107.0, r =   0 }, -- hp 64
            { label = 'Tavnazia 2', zone = xi.zone.TAVNAZIAN_SAFEHOLD, x =  14.0,  y =  -9.96,   z =   -5.0, r =   0 }, -- hp 120
            { label = 'Tavnazia 3', zone = xi.zone.TAVNAZIAN_SAFEHOLD, x =  73.59, y = -36.149,  z =  38.87, r =   0 }, -- hp 121
        },
    },
    {
        name  = 'Past [S]',
        dests =
        {
            { label = "S.San d'Oria [S]", zone = xi.zone.SOUTHERN_SAN_DORIA_S, x =  -85.0, y =   1.0,   z =  -66.0,  r =   0 }, -- hp 68
            { label = 'Bastok Mkts [S]',  zone = xi.zone.BASTOK_MARKETS_S,     x = -293.0, y = -10.0,   z = -102.0,  r =   0 }, -- hp 69
            { label = 'Windy Waters [S]', zone = xi.zone.WINDURST_WATERS_S,    x =  -32.0, y =  -5.0,   z =  131.0,  r =   0 }, -- hp 70
            { label = 'Xarcabard [S]',    zone = xi.zone.XARCABARD_S,          x =  223.0, y = -13.0,   z = -254.0,  r =   0 }, -- hp 111
            { label = 'Zvahl Keep [S]',   zone = xi.zone.CASTLE_ZVAHL_KEEP_S,  x = -554.0, y = -70.0,   z =   66.0,  r = 128 }, -- hp 113
            { label = 'Leafallia',        zone = xi.zone.LEAFALLIA,            x =   5.539, y =  -0.434, z =   8.133, r =  73 }, -- hp 112
        },
    },
    {
        name  = 'Sky',
        dests =
        {
            { label = "Ru'Aun 1",  zone = xi.zone.RUAUN_GARDENS,          x =    5.0, y = -42.0, z =  526.0, r =   0 }, -- hp 59
            { label = "Ru'Aun 2",  zone = xi.zone.RUAUN_GARDENS,          x = -499.0, y = -42.0, z =  167.0, r =   0 }, -- hp 61
            { label = "Ru'Aun 3",  zone = xi.zone.RUAUN_GARDENS,          x = -312.0, y = -42.0, z = -422.0, r =   0 }, -- hp 60
            { label = "Ru'Aun 4",  zone = xi.zone.RUAUN_GARDENS,          x =  500.0, y = -42.0, z =  158.0, r =   0 }, -- hp 62
            { label = "Ru'Aun 5",  zone = xi.zone.RUAUN_GARDENS,          x =  305.0, y = -42.0, z = -427.0, r =   0 }, -- hp 63
            { label = "Ru'Avitau", zone = xi.zone.THE_SHRINE_OF_RUAVITAU, x =  -13.0, y =  48.0, z =   61.0, r =   0 }, -- hp 72
        },
    },
    {
        name  = 'Sea',
        dests =
        {
            { label = "Al'Taieu 1",     zone = xi.zone.ALTAIEU,                x =    7.0, y = 0.0, z =  709.0, r = 192 }, -- hp 85
            { label = "Al'Taieu 2",     zone = xi.zone.ALTAIEU,                x = -532.0, y = 0.0, z =  447.0, r = 128 }, -- hp 86
            { label = "Al'Taieu 3",     zone = xi.zone.ALTAIEU,                x =  569.0, y = 0.0, z =  410.0, r = 192 }, -- hp 87
            { label = "Hu'Xzoi Palace", zone = xi.zone.GRAND_PALACE_OF_HUXZOI, x =  -12.0, y = 0.0, z = -288.0, r = 192 }, -- hp 88
            { label = "Ru'Hmet Garden", zone = xi.zone.THE_GARDEN_OF_RUHMET,   x = -426.0, y = 0.0, z =  368.0, r = 224 }, -- hp 89
        },
    },
    {
        name  = 'Dungeons & Fields',
        dests =
        {
            { label = 'Attohwa Chasm',    zone = xi.zone.ATTOHWA_CHASM,         x = -200.0,   y =  -10.0,  z =  342.0, r =   0 }, -- hp 81
            { label = 'Bhaflau Thickets', zone = xi.zone.BHAFLAU_THICKETS,      x =  -98.0,   y =  -10.0,  z = -493.0, r = 192 }, -- hp 74
            { label = 'Boyahda Tree',     zone = xi.zone.THE_BOYAHDA_TREE,      x =   88.0,   y =  -15.0,  z = -217.0, r =   0 }, -- hp 92
            { label = 'Caedarva Mire',    zone = xi.zone.CAEDARVA_MIRE,         x = -449.0,   y =   13.0,  z = -497.0, r =   0 }, -- hp 75
            { label = 'Cape Teriggan',    zone = xi.zone.CAPE_TERIGGAN,         x = -303.0,   y =   -8.0,  z =  526.0, r =   0 }, -- hp 91
            { label = 'Castle Zvahl',     zone = xi.zone.CASTLE_ZVAHL_KEEP,     x = -554.0,   y =  -70.0,  z =   66.0, r =   0 }, -- hp 58
            { label = 'Den of Rancor 1',  zone = xi.zone.DEN_OF_RANCOR,         x =  -80.0,   y =   46.0,  z =   62.0, r =   0 }, -- hp 57
            { label = 'Den of Rancor 2',  zone = xi.zone.DEN_OF_RANCOR,         x =  182.0,   y =   34.0,  z =  -62.0, r = 223 }, -- hp 93
            { label = "Fei'Yin 1",        zone = xi.zone.FEIYIN,                x =  243.0,   y =  -24.0,  z =   62.0, r =   0 }, -- hp 55
            { label = "Fei'Yin 2",        zone = xi.zone.FEIYIN,                x =  102.0,   y =    0.0,  z =  269.0, r = 191 }, -- hp 94
            { label = 'Giddeus',          zone = xi.zone.GIDDEUS,               x = -132.0,   y =   -3.0,  z = -303.0, r =   0 }, -- hp 54
            { label = "Ifrit's Cauldron", zone = xi.zone.IFRITS_CAULDRON,       x =  -63.0,   y =   50.0,  z =   81.0, r = 192 }, -- hp 95
            { label = 'Misareaux Coast',  zone = xi.zone.MISAREAUX_COAST,       x =  -65.0,   y =  -17.5,  z =  563.0, r = 224 }, -- hp 117
            { label = 'Mount Zhayolm',    zone = xi.zone.MOUNT_ZHAYOLM,         x = -540.844, y =   -4.0,  z =   70.809, r = 74 }, -- hp 90
            { label = 'Newton Moval.',    zone = xi.zone.NEWTON_MOVALPOLOS,     x =  445.0,   y =   27.0,  z =  -22.0, r =   0 }, -- hp 83
            { label = 'Palborough Mines', zone = xi.zone.PALBOROUGH_MINES,      x =  109.0,   y =  -38.0,  z = -147.0, r =   0 }, -- hp 53
            { label = "Pso'Xja",          zone = xi.zone.PSOXJA,                x =  -58.0,   y =   40.0,  z =   14.0, r =  64 }, -- hp 82
            { label = 'Qufim Island',     zone = xi.zone.QUFIM_ISLAND,          x = -212.0,   y =  -21.0,  z =   93.0, r =  64 }, -- hp 114
            { label = 'Quicksand Cv 1',   zone = xi.zone.QUICKSAND_CAVES,       x = -984.0,   y =   17.0,  z = -289.0, r =   0 }, -- hp 56
            { label = 'Quicksand Cv 2',   zone = xi.zone.QUICKSAND_CAVES,       x =  573.0,   y =    9.0,  z = -500.0, r =   0 }, -- hp 96
            { label = 'Riverne A01',      zone = xi.zone.RIVERNE_SITE_A01,      x =  189.0,   y =    0.0,  z =  362.0, r =   0 }, -- hp 84
            { label = 'Riverne B01',      zone = xi.zone.RIVERNE_SITE_B01,      x = -520.0,   y =  -18.0,  z =  505.0, r = 127 }, -- hp 73
            { label = 'Toraimarai Canal', zone = xi.zone.TORAIMARAI_CANAL,      x = -257.5,   y =   24.0,  z =   82.0, r = 192 }, -- hp 115
            { label = 'Uleguerand 1',     zone = xi.zone.ULEGUERAND_RANGE,      x =   64.0,   y = -196.0,  z =  181.0, r =   0 }, -- hp 76
            { label = 'Uleguerand 2',     zone = xi.zone.ULEGUERAND_RANGE,      x =  380.0,   y =   23.0,  z =  -62.0, r =   0 }, -- hp 77
            { label = 'Uleguerand 3',     zone = xi.zone.ULEGUERAND_RANGE,      x =  424.0,   y =  -32.0,  z =  221.0, r =   0 }, -- hp 78
            { label = 'Uleguerand 4',     zone = xi.zone.ULEGUERAND_RANGE,      x =   64.0,   y =  -96.0,  z =  461.0, r =   0 }, -- hp 79
            { label = 'Uleguerand 5',     zone = xi.zone.ULEGUERAND_RANGE,      x = -220.0,   y =   -1.0,  z =  -62.0, r =   0 }, -- hp 80
            { label = 'Upper Delkfutt',   zone = xi.zone.UPPER_DELKFUTTS_TOWER, x = -365.0,   y = -176.5,  z =  -36.0, r =   0 }, -- hp 71
            { label = 'Yughott Grotto',   zone = xi.zone.YUGHOTT_GROTTO,        x =  434.0,   y =  -40.0,  z =  171.0, r =   0 }, -- hp 52
        },
    },
}

return catalog
