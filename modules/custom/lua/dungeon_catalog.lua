-----------------------------------
-- Hybrid dungeon catalogue
-----------------------------------
local catalog = {}

catalog.npc =
{
    zone     = 'Abdhaljs_Isle-Purgonorgo',
    zoneId   = 44,
    x        = 535.000,
    y        = -3.000,
    z        = 574.000,
    rotation = 128,
}

catalog.exit =
{
    zoneId   = 44,
    x        = 521.500,
    y        = -3.000,
    z        = 548.000,
    rotation = 128,
}

catalog.partyRange      = 50
catalog.runTimeMinutes  = 30  -- per-run time limit displayed to players and in docs
catalog.completionDelay = 30
catalog.emptyCloseDelay = 30

local function buildRoster(route, firstName, secondName, bossName, bossHpScale)
    local mobs = {}

    for index, position in ipairs(route) do
        local name
        if index <= 6 then
            name = string.format('%s %02d', firstName, index)
        elseif index <= 12 then
            name = string.format('%s %02d', secondName, index - 6)
        else
            name = bossName
        end

        table.insert(mobs,
        {
            groupId = 11899 + index,
            name    = name,
            x       = position[1],
            y       = position[2],
            z       = position[3],
            r       = position[4] or 127,
            hpScale = index == 13 and bossHpScale or nil,
        })
    end

    return mobs
end

catalog.dungeons =
{
    crawlersNest =
    {
        instanceId = 19700,
        scriptName = 'dungeon_crawlers_nest',
        label      = "Crawlers' Nest",
        zoneName   = 'Crawlers_Nest',
        zoneId     = 197,
        level      = 125,
        hpScale    = 4,
        mobs       = buildRoster(
        {
            { 332.950, -33.111, -18.821, 17  },
            { 315.000, -32.781, -17.000, 127 },
            { 299.000, -32.000, -28.000, 120 },
            { 259.954, -32.979, -53.917, 51  },
            { 258.524, -32.700, -44.000, 127 },
            { 251.000, -32.000, -17.000, 39  },
            { 218.000, -32.787, -18.000, 127 },
            { 189.705, -32.861, -18.955, 92  },
            { 173.000, -32.000, -20.000, 13  },
            { 139.119, -32.817, -23.193, 127 },
            { 124.462, -32.974, -97.487, 6   },
            { 124.000, -32.000, -82.000, 127 },
            { 116.000, -32.000, -78.000, 127 },
        }, 'Dungeon Crawler', 'Dungeon Wasp', 'Nestblight Exoray', 8),
    },

    xarcabard =
    {
        instanceId = 11200,
        scriptName = 'dungeon_xarcabard',
        label      = 'Xarcabard',
        zoneName   = 'Xarcabard',
        zoneId     = 112,
        level      = 120,
        hpScale    = 4,
        mobs       = buildRoster(
        {
            { 564.529, -0.527, -279.526, 25  },
            { 535.266, -1.340, -254.953, 127 },
            { 518.664, -0.342, -269.722, 127 },
            { 516.950, 0.007, -260.931, 127  },
            { 444.050, -0.593, -199.797, 16  },
            { 426.335, -0.087, -200.880, 40  },
            { 423.001, -1.352, -212.330, 127 },
            { 412.379, -0.455, -147.695, 127 },
            { 403.335, -0.300, -165.684, 127 },
            { 399.390, 0.007, -140.021, 127  },
            { 383.716, 0.619, -186.026, 16   },
            { 370.381, 6.034, -166.986, 127  },
            { 347.000, 7.223, -205.000, 127  },
        }, 'Frostbound Demon', 'Rimebound Weapon', 'Glacier Wyrm', 8),
    },

    boyahdaTree =
    {
        instanceId = 15300,
        scriptName = 'dungeon_boyahda_tree',
        label      = 'The Boyahda Tree',
        zoneName   = 'The_Boyahda_Tree',
        zoneId     = 153,
        level      = 125,
        hpScale    = 4,
        mobs       = buildRoster(
        {
            { 417.910, 11.119, -99.093, 205 },
            { 405.430, 11.399, -98.606, 135 },
            { 364.360, 11.605, -99.154, 141 },
            { 345.310, 11.482, -100.750, 27 },
            { 303.380, 8.358, -102.750, 164 },
            { 299.610, 8.395, -83.037, 62   },
            { 297.220, 8.540, -73.097, 185  },
            { 298.560, 8.567, -4.452, 78    },
            { 299.420, 8.636, 5.120, 183    },
            { 303.130, 8.506, 20.774, 100   },
            { 319.540, 8.647, 23.494, 73    },
            { 335.780, 8.481, 16.539, 36    },
            { 320.740, 8.673, -34.479, 119  },
        }, 'Boyahda Crawler', 'Boyahda Crab', 'Ancient Guardian', 8),
    },

    ordellesCaves =
    {
        instanceId = 19300,
        scriptName = 'dungeon_ordelles_caves',
        label      = "Ordelle's Caves",
        zoneName   = 'Ordelles_Caves',
        zoneId     = 193,
        level      = 125,
        hpScale    = 4,
        mobs       = buildRoster(
        {
            { 8.086, 31.688, 195.826, 82   },
            { 4.904, 31.697, 194.255, 104  },
            { -3.216, 31.645, 208.207, 114 },
            { -8.315, 32.020, 195.125, 219 },
            { -11.370, 31.698, 202.837, 135 },
            { -12.470, 32.071, 191.046, 104 },
            { -36.410, 31.940, 219.283, 253 },
            { -43.690, 31.968, 218.671, 12  },
            { -71.360, 31.975, 207.479, 25  },
            { -76.670, 31.163, 186.602, 40  },
            { -80.770, 31.979, 193.542, 112 },
            { -79.820, 31.968, 208.309, 226 },
            { -72.000, 31.975, 215.000, 127 },
        }, 'Ordelle Leech', 'Ordelle Crab', 'Mireheart Slime', 8),
    },

    gusgenMines =
    {
        instanceId = 19600,
        scriptName = 'dungeon_gusgen_mines',
        label      = 'Gusgen Mines',
        zoneName   = 'Gusgen_Mines',
        zoneId     = 196,
        level      = 125,
        hpScale    = 4,
        mobs       = buildRoster(
        {
            { 45.000, -67.000, -320.000, 127  },
            { 42.000, -66.000, -300.000, 127  },
            { 38.000, -64.000, -280.000, 127  },
            { 34.000, -62.000, -260.000, 127  },
            { 28.000, -61.000, -240.000, 127  },
            { 19.490, -60.205, -225.113, 78   },
            { 15.079, -59.919, -216.982, 131  },
            { 20.000, -60.234, -212.000, 68   },
            { 13.000, -59.000, -183.000, 18   },
            { 19.282, -59.874, -175.445, 127  },
            { -14.282, -59.900, -177.424, 15 },
            { -28.088, -59.560, -180.088, 127 },
            { -60.000, -59.000, -177.000, 127 },
        }, 'Gusgen Skeleton', 'Gusgen Hound', 'Grieving Spirit', 8),
    },

    kuftalTunnel =
    {
        instanceId = 17400,
        scriptName = 'dungeon_kuftal_tunnel',
        label      = 'Kuftal Tunnel',
        zoneName   = 'Kuftal_Tunnel',
        zoneId     = 174,
        level      = 125,
        hpScale    = 4,
        mobs       = buildRoster(
        {
            { 57.000, -10.000, 260.000, 19   },
            { 53.604, -11.836, 251.394, 127  },
            { 60.398, -10.361, 252.211, 127  },
            { 61.791, -10.452, 244.355, 21   },
            { 79.000, -10.000, 220.000, 39   },
            { 69.106, -11.538, 209.402, 127  },
            { 91.000, -9.000, 220.000, 127   },
            { 60.906, -9.031, 198.387, 127   },
            { 55.524, -6.611, 190.474, 127   },
            { 100.000, -9.000, 215.000, 127  },
            { 61.000, -5.000, 185.000, 127   },
            { 97.554, -10.378, 202.466, 127  },
            { 99.755, -10.762, 188.715, 127  },
        }, 'Kuftal Worm', 'Kuftal Lizard', 'Needleback', 8),
    },

    gustavTunnel =
    {
        instanceId = 21200,
        scriptName = 'dungeon_gustav_tunnel',
        label      = 'Gustav Tunnel',
        zoneName   = 'Gustav_Tunnel',
        zoneId     = 212,
        level      = 125,
        hpScale    = 4,
        mobs       = buildRoster(
        {
            { 334.000, -33.000, 53.000, 118   },
            { 323.000, -30.884, 20.000, 127   },
            { 300.000, -25.000, 21.000, 100   },
            { 278.257, -20.612, 20.825, 127   },
            { 261.059, -19.390, -7.422, 127   },
            { 245.000, -19.000, -20.000, 127  },
            { 238.000, -18.000, -19.000, 127  },
            { 216.000, -20.000, -21.000, 127  },
            { 176.948, -11.418, -28.134, 104  },
            { 165.974, -10.632, -75.974, 127  },
            { 164.000, -10.000, -39.000, 28   },
            { 149.570, -10.345, -38.308, 127  },
            { 141.000, -10.000, -51.000, 63   },
        }, 'Gustav Bat', 'Gustav Fly', 'Ironclaw', 8),
    },

    ifritsCauldron =
    {
        instanceId = 20500,
        scriptName = 'dungeon_ifrits_cauldron',
        label      = "Ifrit's Cauldron",
        zoneName   = 'Ifrits_Cauldron',
        zoneId     = 205,
        level      = 125,
        hpScale    = 4,
        mobs       = buildRoster(
        {
            { 54.808, 3.279, -269.640, 205   },
            { 45.000, 3.724, -288.000, 127   },
            { 37.842, 3.999, -276.772, 127   },
            { 31.587, 3.678, -290.794, 43    },
            { 28.481, 3.858, -276.021, 64    },
            { 11.646, 3.818, -282.359, 80    },
            { 0.851, 4.052, -292.000, 127     },
            { 0.279, 4.000, -269.457, 127     },
            { -14.216, 3.908, -278.581, 92   },
            { -39.907, -0.030, -300.534, 3  },
            { -59.585, 0.201, -275.523, 63   },
            { -62.700, 0.168, -294.868, 111  },
            { -70.178, 3.939, -243.403, 83   },
        }, 'Cauldron Bomb', 'Cauldron Goblin', 'Cinderlord Ifrit', 8),
    },

    feiYin =
    {
        instanceId = 20400,
        scriptName = 'dungeon_feiyin',
        label      = 'Fei-Yin',
        zoneName   = 'FeiYin',
        zoneId     = 204,
        level      = 125,
        hpScale    = 4,
        mobs       = buildRoster(
        {
            { -49.720, -0.112, 5.450, 104   },
            { -51.190, -0.018, 32.207, 251  },
            { -62.330, -0.500, 19.027, 10   },
            { -71.840, -0.112, 30.037, 129  },
            { -90.000, -0.112, 72.000, 37   },
            { -87.730, -0.108, 90.366, 172  },
            { -90.480, -0.024, 111.930, 225 },
            { -109.895, -0.500, 103.436, 35 },
            { -129.795, -0.500, 96.757, 194 },
            { -151.900, -0.107, 90.239, 205 },
            { -48.000, -0.112, 110.000, 67  },
            { -60.290, 0.462, 166.503, 180  },
            { -77.430, 0.462, 164.529, 145  },
        }, "Fei'Yin Golem", "Fei'Yin Pot", 'Frostmaw Morbol', 8),
    },

    ranguemontPass =
    {
        instanceId = 16600,
        scriptName = 'dungeon_ranguemont_pass',
        label      = 'Ranguemont Pass',
        zoneName   = 'Ranguemont_Pass',
        zoneId     = 166,
        level      = 125,
        hpScale    = 4,
        mobs       = buildRoster(
        {
            { -187.556, 3.383, -148.428, 127 },
            { -171.000, 5.000, -165.000, 101 },
            { -186.000, 5.000, -166.000, 66  },
            { -189.958, 4.596, -144.100, 127 },
            { -190.599, 4.586, -143.857, 128 },
            { -197.619, 4.469, -143.783, 192 },
            { -179.000, 5.000, -182.000, 2   },
            { -209.311, 2.998, -149.195, 5   },
            { -209.388, 4.470, -144.834, 127 },
            { -207.632, 3.068, -134.052, 9   },
            { -172.000, 5.000, -191.000, 127 },
            { -188.000, 5.000, -191.000, 64  },
            { -217.000, 4.000, -189.000, 97  },
        }, 'Ranguemont Eye', 'Ranguemont Weapon', 'Watcher Ahriman', 8),
    },
}

catalog.categories =
{
    {
        label       = 'Challenge Dungeons',
        dungeonKeys = { 'crawlersNest' },
    },
    {
        label       = 'Progression Dungeons',
        dungeonKeys = { 'xarcabard', 'boyahdaTree' },
    },
    {
        label       = 'Augmentation Dungeons',
        dungeonKeys =
        {
            'ordellesCaves',
            'gusgenMines',
            'kuftalTunnel',
            'gustavTunnel',
            'ifritsCauldron',
            'feiYin',
            'ranguemontPass',
        },
    },
}

catalog.getDungeonByZoneId = function(zoneId)
    for _, dungeon in pairs(catalog.dungeons) do
        if dungeon.zoneId == zoneId then
            return dungeon
        end
    end

    return nil
end

catalog.getDungeonByInstanceId = function(instanceId)
    for _, dungeon in pairs(catalog.dungeons) do
        if dungeon.instanceId == instanceId then
            return dungeon
        end
    end

    return nil
end

return catalog
