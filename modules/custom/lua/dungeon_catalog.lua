-----------------------------------
-- Hybrid dungeon catalogue
-----------------------------------
local catalog = {}

catalog.npc =
{
    zone     = 'Abdhaljs_Isle-Purgonorgo',
    zoneId   = 44,
    x        = 618.000,
    y        = -3.360,
    z        = 521.500,
    rotation = 135,
}

catalog.exit =
{
    zoneId   = 44,
    x        = 571.471,
    y        = -3.360,
    z        = 512.586,
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
            -- Wasps 07-12 + Nestblight Exoray boss (13) trailed deep into the nest
            -- (X 116-218 -- likely disconnected rooms). Proactively pulled into the
            -- reachable entrance run beside Crawlers 01-06 (adjacent midpoints, same
            -- -32 floor). PROACTIVE/UNVERIFIED in-game -- report if a straggler remains.
            { 324.000, -32.950, -17.900, 127 },
            { 307.000, -32.390, -22.500, 127 },
            { 279.500, -32.490, -41.000, 127 },
            { 259.200, -32.840, -49.000, 127 },
            { 254.800, -32.350, -30.500, 127 },
            { 328.000, -33.000, -18.300, 127 },
            { 299.000, -32.000, -25.000, 127 }, -- Nestblight Exoray (boss), centered
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
            -- PROACTIVE reachability fix (2026-07-07, unverified): 5 far
            -- mobs pulled from disconnected sections into the reachable cluster
            -- near the instance start (594.4312, 0.192, -258.5914); midpoints of kept points.
            { 564.529, -0.527, -279.526, 25 },
            { 535.266, -1.34, -254.953, 127 },
            { 518.664, -0.342, -269.722, 127 },
            { 516.95, 0.007, -260.931, 127 },
            { 444.05, -0.593, -199.797, 16 },
            { 426.335, -0.087, -200.88, 40 },
            { 423.001, -1.352, -212.33, 127 },
            { 549.898, -0.933, -267.24, 127 }, -- relocated
            { 403.335, -0.3, -165.684, 127 },
            { 526.965, -0.841, -262.337, 127 }, -- relocated
            { 517.807, -0.168, -265.327, 127 }, -- relocated
            { 480.5, -0.293, -230.364, 127 }, -- relocated
            { 479.016, -0.567, -230.478, 127 }, -- boss, cluster center
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
            -- Crawlers 01-04 were on the UPPER Y~11 ledge (X 345-418, Z -99), but the
            -- instance drops players onto the Y~8.5 level (start_y 8.81), so these four
            -- were stranded overhead and unreachable. Moved down to the Y~8.5 floor
            -- beside Crawler 06/07. 05-13 (incl. the Ancient Guardian boss) already sit
            -- on the reachable level. PROACTIVE/UNVERIFIED -- report if a straggler remains.
            { 301.000, 8.450, -85.000, 205 },
            { 298.000, 8.450, -80.000, 135 },
            { 299.500, 8.500, -70.000, 141 },
            { 296.000, 8.500, -76.000, 27  },
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
            -- Crabs 07-12 + Mireheart Slime boss (13) were at X -36..-80 -- a
            -- disconnected maze section players couldn't reach, so the boss never
            -- came into view ("11 remain, can't find them", Duff 2026-07-07).
            -- Relocated into the reachable entrance chamber (midpoints of the six
            -- confirmed-walkable Leech points above); boss centered.
            { 6.500, 31.690, 195.000, 127  },
            { -1.700, 31.660, 194.700, 127 },
            { -9.850, 31.860, 199.000, 127 },
            { -7.300, 31.670, 205.500, 127 },
            { 2.450, 31.670, 202.000, 127  },
            { -10.400, 31.880, 193.050, 127 },
            { -4.000, 31.700, 199.000, 127 }, -- Mireheart Slime (boss), centered
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
            -- Skeleton 01-03,05: original round-number coords clipped walls (Duff 2026-07-06).
            -- Replaced with verified stock Gusgen (zone 196) floor spawn points. 04 left as-is
            -- (Duff confirmed it reachable). Boss (idx 13) moved to the far platform per Duff.
            { 18.982, -59.922, -169.474, 127  }, -- 01 (was 45,-67,-320 in wall)
            { -58.000, -59.826, -207.000, 127 }, -- 02 (was 42,-66,-300 in wall)
            { -47.129, -60.036, -218.823, 57  }, -- 03 (was 38,-64,-280 in wall)
            { 34.000, -62.000, -260.000, 127  }, -- 04 (reachable, unchanged)
            { 69.590, -59.701, -181.616, 127  }, -- 05 (was 28,-61,-240 in wall)
            { 19.490, -60.205, -225.113, 78   },
            { 15.079, -59.919, -216.982, 131  },
            { 20.000, -60.234, -212.000, 68   },
            { 13.000, -59.000, -183.000, 18   },
            { 19.282, -59.874, -175.445, 127  },
            { -14.282, -59.900, -177.424, 15 },
            { -28.088, -59.560, -180.088, 127 },
            { 20.000, -60.000, -13.000, 127 }, -- boss: far platform (was -60,-59,-177 near entrance)
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
            -- PROACTIVE reachability fix (2026-07-07, unverified): 5 far
            -- mobs pulled from disconnected sections into the reachable cluster
            -- near the instance start (44.42, -9.893, 260.3208); midpoints of kept points.
            { 57.0, -10.0, 260.0, 19 },
            { 53.604, -11.836, 251.394, 127 },
            { 60.398, -10.361, 252.211, 127 },
            { 61.791, -10.452, 244.355, 21 },
            { 79.0, -10.0, 220.0, 39 },
            { 69.106, -11.538, 209.402, 127 },
            { 91.0, -9.0, 220.0, 127 },
            { 60.906, -9.031, 198.387, 127 },
            { 55.302, -10.918, 255.697, 127 }, -- relocated
            { 57.001, -11.099, 251.803, 127 }, -- relocated
            { 61.094, -10.407, 248.283, 127 }, -- relocated
            { 70.395, -10.226, 232.178, 127 }, -- relocated
            { 66.601, -10.277, 231.969, 127 }, -- boss, cluster center
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
            -- PROACTIVE reachability fix (2026-07-07, unverified): 5 far
            -- mobs pulled from disconnected sections into the reachable cluster
            -- near the instance start (300.8949, -40.1816, 69.8268); midpoints of kept points.
            { 334.0, -33.0, 53.0, 118 },
            { 323.0, -30.884, 20.0, 127 },
            { 300.0, -25.0, 21.0, 100 },
            { 278.257, -20.612, 20.825, 127 },
            { 261.059, -19.39, -7.422, 127 },
            { 245.0, -19.0, -20.0, 127 },
            { 238.0, -18.0, -19.0, 127 },
            { 216.0, -20.0, -21.0, 127 },
            { 328.5, -31.942, 36.5, 127 }, -- relocated
            { 311.5, -27.942, 20.5, 127 }, -- relocated
            { 289.129, -22.806, 20.913, 127 }, -- relocated
            { 269.658, -20.001, 6.701, 127 }, -- relocated
            { 274.414, -23.236, 5.925, 127 }, -- boss, cluster center
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
            -- PROACTIVE reachability fix (2026-07-07, unverified): 5 far
            -- mobs pulled from disconnected sections into the reachable cluster
            -- near the instance start (98.1775, 0.3434, -301.9413); midpoints of kept points.
            { 54.808, 3.279, -269.64, 205 },
            { 45.0, 3.724, -288.0, 127 },
            { 37.842, 3.999, -276.772, 127 },
            { 31.587, 3.678, -290.794, 43 },
            { 28.481, 3.858, -276.021, 64 },
            { 11.646, 3.818, -282.359, 80 },
            { 0.851, 4.052, -292.0, 127 },
            { 0.279, 4.0, -269.457, 127 },
            { 49.904, 3.502, -278.82, 127 }, -- relocated
            { 41.421, 3.862, -282.386, 127 }, -- relocated
            { 34.715, 3.838, -283.783, 127 }, -- relocated
            { 30.034, 3.768, -283.408, 127 }, -- relocated
            { 26.312, 3.801, -280.63, 127 }, -- boss, cluster center
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
            -- PROACTIVE reachability fix (2026-07-07, unverified): 5 far
            -- mobs pulled from disconnected sections into the reachable cluster
            -- near the instance start; midpoints of kept points.
            -- 2026-07-09: the instance start itself moved to the stock Talos
            -- point (-49.72, -0.112, 5.45) -- the old (-40, 0, -5) floated 16
            -- yalms above the real floor (Jamesta: spawned outside the map).
            -- The mob that sat on the Talos point moved ~18y up the corridor
            -- (between the stock Goblin_Bandit and Talos camps) so players
            -- don't zone in on top of a golem.
            { -52.0, -0.25, 24.0, 104 },
            { -51.19, -0.018, 32.207, 251 },
            { -62.33, -0.5, 19.027, 10 },
            { -71.84, -0.112, 30.037, 129 },
            { -90.0, -0.112, 72.0, 37 },
            { -87.73, -0.108, 90.366, 172 },
            { -90.48, -0.024, 111.93, 225 },
            { -50.455, -0.065, 18.829, 127 }, -- relocated
            { -56.76, -0.259, 25.617, 127 }, -- relocated
            { -67.085, -0.306, 24.532, 127 }, -- relocated
            { -48.0, -0.112, 110.0, 67 },
            { -80.92, -0.112, 51.019, 127 }, -- relocated
            { -68.911, -0.137, 58.877, 127 }, -- boss, cluster center
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
            -- Reachability fix (2026-07-11, Lant's report): the retail one-way
            -- Granite Door at (-180, -159) seals the southern chamber network
            -- (z -165..-191) off from the instance start (-178.8, -154.9), and
            -- the zoning leash blocks the long way around. The 6 points that
            -- sat beyond the door moved into the spawn-side goblin camp
            -- (midpoints of the kept stock points; boss to the cluster center).
            { -187.556, 3.383, -148.428, 127 },
            { -188.757, 3.990, -146.264, 127 }, -- relocated
            { -193.789, 4.533, -143.942, 127 }, -- relocated
            { -189.958, 4.596, -144.100, 127 },
            { -190.599, 4.586, -143.857, 128 },
            { -197.619, 4.469, -143.783, 192 },
            { -203.504, 4.470, -144.309, 127 }, -- relocated
            { -209.311, 2.998, -149.195, 5   },
            { -209.388, 4.470, -144.834, 127 },
            { -207.632, 3.068, -134.052, 9   },
            { -203.465, 3.734, -146.489, 127 }, -- relocated
            { -208.510, 3.769, -139.443, 127 }, -- relocated
            { -198.866, 3.939, -144.036, 127 }, -- boss, cluster center
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

-----------------------------------
-- Boss mechanics (owner 2026-07-12 audit: bosses previously had HP-scaled
-- retail kit only -- felt indistinguishable per dungeon). Each cfg is consumed
-- by modules/custom/lua/mob_mechanics_library.lua via mechanics.attach(mob, cfg)
-- from dungeon_instance.lua's spawnDungeonMob when the boss slot spawns.
--
-- Tuning target: dungeons are 30-min timed clears at ILV 125 with hpScale=8;
-- these sit roughly at Hunting League Rank III intensity -- memorable pressure
-- without wall-tier lockouts. Enrage timers land around 200-240s so a clean
-- clear beats them, a slow clear feels them.
-----------------------------------
catalog.bossMechCfgs =
{
    -- Fungus/spore theme: parasitic drain + poison cloud + spore burst.
    crawlersNest =
    {
        name            = 'Nestblight Exoray',
        targetPartyOnly = true,
        drain  = { periodSec = 8,  healPct = 3 },
        cc     = { periodSec = 30, effect = xi.effect.POISON, power = 250, dur = 30, msg = 'Nestblight Exoray releases a cloud of noxious spores!' },
        aoe    = { periodSec = 15, dmgPct = 18, msg = 'Nestblight Exoray erupts -- fungal spores burst outward!' },
        enrage = { sec = 240, att = 3500, haste = 100, msg = 'Nestblight Exoray swells -- the whole colony vibrates with rage!' },
    },

    -- Ice wyrm: phys/mag stance dance + freezing breath + two flight phases.
    xarcabard =
    {
        name            = 'Glacier Wyrm',
        targetPartyOnly = true,
        stance = { startHpp = 90, periodSec = 16, stances = {
            { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'Glacier Wyrm\'s scales sheet with ice -- use magic!' },
            { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'Glacier Wyrm shrugs off magic -- cut it with steel!' },
        } },
        aoe    = { periodSec = 13, dmgPct = 22, msg = 'Glacier Wyrm inhales -- a frost breath is coming!' },
        enrage = { sec = 220, att = 4000, haste = 120, msg = 'Glacier Wyrm rears back -- the whole cavern chills!' },
        phases =
        {
            { hp = 66, action = 'fury', att = 2500, haste = 90,  msg = 'Glacier Wyrm takes flight -- its assault quickens!' },
            { hp = 33, action = 'fury', att = 3500, haste = 120, msg = 'Glacier Wyrm slams down in a bloodied frenzy!' },
        },
    },

    -- Treant/golem: root-fed drain + bark stance + wind-shear dispel at 40%.
    boyahdaTree =
    {
        name            = 'Ancient Guardian',
        targetPartyOnly = true,
        drain  = { periodSec = 8, healPct = 3 },
        stance = { startHpp = 85, periodSec = 18, stances = {
            { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'Ancient Guardian\'s bark thickens -- iron will not bite!' },
            { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'Ancient Guardian shrugs off spellcraft -- strike with steel!' },
        } },
        enrage = { sec = 240, att = 3500, haste = 100, msg = 'Ancient Guardian creaks -- its roots draw fresh strength!' },
        phases =
        {
            { hp = 40, action = 'dispel', count = 3, msg = 'Ancient Guardian sheds a wind of leaves -- your blessings scatter!' },
        },
    },

    -- Ooze: heavy consume-drain + acid burst + two "split & reform" fury phases.
    ordellesCaves =
    {
        name            = 'Mireheart Slime',
        targetPartyOnly = true,
        drain  = { periodSec = 7,  healPct = 4 },
        aoe    = { periodSec = 11, dmgPct = 18, msg = 'Mireheart Slime bursts -- acid sprays in every direction!' },
        enrage = { sec = 240, att = 3500, haste = 100, msg = 'Mireheart Slime coalesces -- a single ferocious mass rises!' },
        phases =
        {
            { hp = 66, action = 'fury', att = 2500, haste = 90,  msg = 'Mireheart Slime splits -- and reforms tougher!' },
            { hp = 33, action = 'fury', att = 3000, haste = 110, msg = 'Mireheart Slime pulses -- devouring the cavern floor for strength!' },
        },
    },

    -- Wraith: soul-drain + terror wail + mourning AoE + low-HP doom mark.
    gusgenMines =
    {
        name            = 'Grieving Spirit',
        targetPartyOnly = true,
        drain  = { periodSec = 8,  healPct = 3 },
        cc     = { periodSec = 22, effect = xi.effect.TERROR, power = 1, dur = 5, msg = 'Grieving Spirit wails -- the dread stills your heart!' },
        aoe    = { periodSec = 14, dmgPct = 20, msg = 'Grieving Spirit mourns -- a wave of sorrow crushes the party!' },
        enrage = { sec = 230, att = 4000, haste = 120, msg = 'Grieving Spirit fills with fury -- the mines groan!' },
        doom   = { startHpp = 15, dur = 25, msg = 'Grieving Spirit marks you for the grave!' },
    },

    -- Worm/spike: rapid needle spray AoE + BIND barbs + spike-fury phase.
    kuftalTunnel =
    {
        name            = 'Needleback',
        targetPartyOnly = true,
        aoe    = { periodSec = 10, dmgPct = 20, msg = 'Needleback fires a volley of spines!' },
        cc     = { periodSec = 20, effect = xi.effect.BIND, power = 1, dur = 6, msg = 'Needleback\'s barbs snag you in place!' },
        enrage = { sec = 240, att = 3500, haste = 100, msg = 'Needleback\'s spines glow -- every barb aches to fire!' },
        phases =
        {
            { hp = 40, action = 'fury', att = 3000, haste = 100, msg = 'Needleback bristles -- its whole hide rises like blades!' },
        },
    },

    -- Bat/fly swarm: heavy blood-drain + wing-buffet AoE + brutal fast enrage.
    gustavTunnel =
    {
        name            = 'Ironclaw',
        targetPartyOnly = true,
        drain  = { periodSec = 7,  healPct = 4 },
        aoe    = { periodSec = 12, dmgPct = 17, msg = 'Ironclaw whirls up a storm of wings and claws!' },
        enrage = { sec = 200, att = 4500, haste = 140, msg = 'Ironclaw flies into a killing frenzy!' },
    },

    -- Fire lord: big fire-nova AoE + molten stance + flare-dispel + meteor + doom.
    ifritsCauldron =
    {
        name            = 'Cinderlord Ifrit',
        targetPartyOnly = true,
        aoe    = { periodSec = 12, dmgPct = 25, msg = 'Cinderlord Ifrit ignites -- a fire nova rolls out!' },
        stance = { startHpp = 85, periodSec = 16, stances = {
            { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'Cinderlord Ifrit\'s flame-shell hardens -- steel is useless!' },
            { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'Cinderlord Ifrit turns molten -- magic runs off it!' },
        } },
        enrage = { sec = 210, att = 4500, haste = 130, msg = 'Cinderlord Ifrit\'s core detonates -- the cauldron trembles!' },
        phases =
        {
            { hp = 60, action = 'dispel', count = 3,            msg = 'Cinderlord Ifrit exhales flare wind -- your enhancements burn away!' },
            { hp = 30, action = 'nuke',   dmgPct = 45,          msg = 'Cinderlord Ifrit hurls a meteor!' },
        },
        doom   = { startHpp = 15, dur = 25, msg = 'Cinderlord Ifrit marks you for immolation!' },
    },

    -- Morbol: silencing bad breath + frozen breath AoE + full-dispel bad breath at 50%.
    feiYin =
    {
        name            = 'Frostmaw Morbol',
        targetPartyOnly = true,
        cc     = { periodSec = 20, effect = xi.effect.SILENCE, power = 1, dur = 6, msg = 'Frostmaw Morbol exhales -- the fumes silence the party!' },
        aoe    = { periodSec = 13, dmgPct = 20, msg = 'Frostmaw Morbol coughs up a frozen breath cloud!' },
        enrage = { sec = 230, att = 4000, haste = 110, msg = 'Frostmaw Morbol\'s vines lash -- it goes berserk!' },
        phases =
        {
            { hp = 50, action = 'dispel', count = 4, msg = 'Frostmaw Morbol unleashes its full Bad Breath -- everything is stripped!' },
        },
    },

    -- Multi-eye ahriman: fastest stance dance + silencing Chaotic Eye + petrifying
    -- gaze AoE + Evil-Eye-open dispel + fury + doom. Toughest of the 10.
    ranguemontPass =
    {
        name            = 'Watcher Ahriman',
        targetPartyOnly = true,
        stance = { startHpp = 80, periodSec = 14, stances = {
            { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'Watcher Ahriman blinks -- weapon strikes glance off!' },
            { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'Watcher Ahriman\'s pupils dilate -- magic scatters!' },
        } },
        cc     = { periodSec = 22, effect = xi.effect.SILENCE, power = 1, dur = 7, msg = 'Watcher Ahriman opens a Chaotic Eye -- your voice fails!' },
        aoe    = { periodSec = 12, dmgPct = 22, msg = 'Watcher Ahriman glares -- a petrifying gaze sweeps the room!' },
        enrage = { sec = 210, att = 5000, haste = 140, msg = 'Watcher Ahriman\'s eyes bulge -- every pupil ignites!' },
        phases =
        {
            { hp = 60, action = 'dispel', count = 4,            msg = 'Watcher Ahriman opens every eye -- your blessings vanish!' },
            { hp = 30, action = 'fury',   att = 3000, haste = 120, msg = 'Watcher Ahriman roars -- pupils flare crimson!' },
        },
        doom   = { startHpp = 12, dur = 25, msg = 'Watcher Ahriman fixes you with an Evil Eye!' },
    },
}

-----------------------------------
-- Trash mechanics (owner 2026-07-12 audit follow-up: dungeon trash was pure
-- stat-block mobs -- felt indistinguishable from any retail pull). Same wiring
-- as bossMechCfgs: dungeon_instance.lua's spawnDungeonMob attaches these when a
-- non-boss slot spawns, keyed by dungeonKey then by mob-type slot.
--
-- Roster convention (see buildRoster above): slots 1-6 spawn firstName mobs
-- (e.g. Dungeon Crawler); slots 7-12 spawn secondName (Dungeon Wasp). So `first`
-- is the pack lead-mob's cfg, `second` is the follow-up mob's cfg. Slot 13 is
-- the boss (uses bossMechCfgs instead).
--
-- Stacking safety: trash dies fast + up to 12 of them can be engaged at once.
-- Every cfg here uses AT MOST ONE mechanic:
--   * drain          -- silent per-mob self-heal, safe to stack across all 12
--   * cc (single ping) -- addStatusEffect no-ops on duplicates, so a linked pack
--                        firing the same effect resolves to one application
-- NO aoe (per-mob damage stacks -- 6 mobs at 5% dmgPct = 30% max HP burst).
-- NO phases / doom / enrage (trash die before those windows land meaningfully).
-- CC periods sit at 18-28s so most solo pulls don't see them; linked/AoE pulls
-- eat one refresh per effect while the pack is up.
-----------------------------------
catalog.trashMechCfgs =
{
    crawlersNest =
    {
        first  = { name = 'Dungeon Crawler', targetPartyOnly = true, drain = { periodSec = 10, healPct = 3 } },
        second = { name = 'Dungeon Wasp',    targetPartyOnly = true, cc = { periodSec = 20, effect = xi.effect.PARALYZE, power = 30, dur = 5, msg = 'A Dungeon Wasp\'s sting paralyses!' } },
    },

    xarcabard =
    {
        first  = { name = 'Frostbound Demon', targetPartyOnly = true, cc = { periodSec = 22, effect = xi.effect.PARALYZE, power = 40, dur = 6, msg = 'Frostbound Demon\'s aura chills your muscles!' } },
        second = { name = 'Rimebound Weapon', targetPartyOnly = true, drain = { periodSec = 10, healPct = 3 } },
    },

    boyahdaTree =
    {
        first  = { name = 'Boyahda Crawler', targetPartyOnly = true, drain = { periodSec = 9,  healPct = 3 } },
        second = { name = 'Boyahda Crab',    targetPartyOnly = true, cc = { periodSec = 22, effect = xi.effect.BIND, power = 1, dur = 5, msg = 'A Boyahda Crab clamps its pincer around you!' } },
    },

    ordellesCaves =
    {
        first  = { name = 'Ordelle Leech', targetPartyOnly = true, drain = { periodSec = 8,  healPct = 4 } },
        second = { name = 'Ordelle Crab',  targetPartyOnly = true, cc = { periodSec = 22, effect = xi.effect.BIND, power = 1, dur = 5, msg = 'An Ordelle Crab pins you with its pincers!' } },
    },

    gusgenMines =
    {
        first  = { name = 'Gusgen Skeleton', targetPartyOnly = true, cc = { periodSec = 24, effect = xi.effect.TERROR, power = 1, dur = 3, msg = 'A Gusgen Skeleton\'s hollow gaze freezes you!' } },
        second = { name = 'Gusgen Hound',    targetPartyOnly = true, drain = { periodSec = 10, healPct = 3 } },
    },

    kuftalTunnel =
    {
        first  = { name = 'Kuftal Worm',   targetPartyOnly = true, drain = { periodSec = 10, healPct = 3 } },
        second = { name = 'Kuftal Lizard', targetPartyOnly = true, cc = { periodSec = 22, effect = xi.effect.PARALYZE, power = 30, dur = 5, msg = 'A Kuftal Lizard\'s bite floods you with neurotoxin!' } },
    },

    gustavTunnel =
    {
        first  = { name = 'Gustav Bat', targetPartyOnly = true, drain = { periodSec = 8,  healPct = 4 } },
        second = { name = 'Gustav Fly', targetPartyOnly = true, cc = { periodSec = 20, effect = xi.effect.SILENCE, power = 1, dur = 5, msg = 'A Gustav Fly buzzes past your ear -- silence!' } },
    },

    ifritsCauldron =
    {
        first  = { name = 'Cauldron Bomb',   targetPartyOnly = true, drain = { periodSec = 10, healPct = 3 } },
        second = { name = 'Cauldron Goblin', targetPartyOnly = true, cc = { periodSec = 22, effect = xi.effect.BIND, power = 1, dur = 5, msg = 'A Cauldron Goblin flings a molten net -- bound!' } },
    },

    feiYin =
    {
        first  = { name = "Fei'Yin Golem", targetPartyOnly = true, cc = { periodSec = 24, effect = xi.effect.BIND, power = 1, dur = 5, msg = "A Fei'Yin Golem locks you in a stone grasp!" } },
        second = { name = "Fei'Yin Pot",   targetPartyOnly = true, cc = { periodSec = 20, effect = xi.effect.SILENCE, power = 1, dur = 5, msg = "A Fei'Yin Pot vents freezing gas -- silenced!" } },
    },

    ranguemontPass =
    {
        first  = { name = 'Ranguemont Eye',    targetPartyOnly = true, cc = { periodSec = 20, effect = xi.effect.SILENCE, power = 1, dur = 5, msg = 'A Ranguemont Eye opens on you -- your voice fails!' } },
        second = { name = 'Ranguemont Weapon', targetPartyOnly = true, drain = { periodSec = 10, healPct = 3 } },
    },
}

return catalog
