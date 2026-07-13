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
            -- Roster fully rebuilt from retail zone-112 stock spawn coords
            -- (2026-07-13, Lant's "1 mob + boss inside wall" report). Xarcabard
            -- stock density near entry is thin -- only 4 unique Lost_Soul
            -- points within 100u of entry, then an 84u gap. The 4 close coords
            -- repeat 3x each for the 12 trash slots (safe: mobs are dynamic
            -- entities with unique groupIds, they stack visually but don't
            -- collide). The old (479, -0.5, -230) boss was between the two
            -- tiers matching NO stock spawn -- that's the wall-clip source.
            { 564.530, -0.530, -279.530,  25 },   -- Lost_Soul   36.5u
            { 535.270, -1.340, -254.950, 127 },   -- Lost_Soul   59.3u
            { 518.660, -0.340, -269.720, 127 },   -- Lost_Soul   76.6u
            { 516.950,  0.010, -260.930, 127 },   -- Lost_Soul   77.5u
            { 564.530, -0.530, -279.530,  25 },   -- Lost_Soul  (dup)
            { 535.270, -1.340, -254.950, 127 },   -- Lost_Soul  (dup)
            { 518.660, -0.340, -269.720, 127 },   -- Lost_Soul  (dup)
            { 516.950,  0.010, -260.930, 127 },   -- Lost_Soul  (dup)
            { 564.530, -0.530, -279.530,  25 },   -- Lost_Soul  (dup)
            { 535.270, -1.340, -254.950, 127 },   -- Lost_Soul  (dup)
            { 518.660, -0.340, -269.720, 127 },   -- Lost_Soul  (dup)
            { 516.950,  0.010, -260.930, 127 },   -- Lost_Soul  (dup)
            { 444.050, -0.590, -199.800,  16 },   -- Glacier Wyrm boss (161.5u)
        }, 'Frostbound Demon', 'Rimebound Weapon', 'Glacier Wyrm', 8),
        -- Boss coord 161u from entry -- per-dungeon leash 175u to include it.
        leash = 175,
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
            -- Roster fully rebuilt from retail zone-153 stock spawn coords
            -- (2026-07-13, Ropraz's early boss-order report + general cleanup).
            -- Cluster follows the west z=-99..-105 corridor from entry into the
            -- Death_Cap chamber at the dead end. Avoids the perpendicular
            -- z=-25 tunnel that was catching players sideways.
            { 417.910, 11.120,  -99.090, 205 },   -- Bark_Spider     33.6u
            { 405.430, 11.400,  -98.610, 135 },   -- Bark_Spider     36.8u
            { 364.360, 11.610,  -99.150, 141 },   -- Bark_Spider     66.6u
            { 345.310, 11.480, -100.750,  27 },   -- Bark_Spider     84.2u
            { 299.610,  8.390,  -83.040,  62 },   -- Bark_Spider    123.5u
            { 303.380,  8.360, -102.750, 164 },   -- Death_Cap      124.1u
            { 297.220,  8.540,  -73.100, 185 },   -- Bark_Spider    124.9u
            { 290.120,  7.990, -105.880, 241 },   -- Death_Cap      137.7u
            { 287.370,  7.760, -102.740,  29 },   -- Death_Cap      139.5u
            { 286.350,  7.090,  -99.000, 222 },   -- Death_Cap      139.6u
            { 265.290,  8.550, -100.020, 158 },   -- Bark_Spider    160.3u
            { 264.020,  8.530,  -98.120,  42 },   -- Bark_Spider    161.1u
            { 260.990,  8.510, -102.200, 253 },   -- Ancient Guardian boss 165.0u
        }, 'Boyahda Crawler', 'Boyahda Crab', 'Ancient Guardian', 8),
        -- Boss ~165u from entry (corridor dead end); leash 180u to include it.
        leash = 180,
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
            -- Roster fully rebuilt from retail zone-196 stock spawn coords
            -- (2026-07-13, Lant's "you spawn underground" + Ropraz's zone-line
            -- to Oldton reports). Every coord verbatim from stock. Cluster
            -- sits in the central Gusgen chamber (x=-55..+70, z=-225..-176)
            -- -- well inside the map interior, away from the Oldton zone-line
            -- at the map edge. Entry Y in dungeon_instances.sql corrected
            -- from -67.88 (underground) to -60.20 (walkable floor).
            { 19.490, -60.200, -225.110,  78 },   -- Skeleton_Warrior 118.3u
            { 15.080, -59.920, -216.980, 131 },   -- Skeleton_Warrior 127.2u
            { 15.000, -59.880, -217.000, 109 },   -- Ghoul            127.2u
            { 20.000, -60.230, -212.000,  68 },   -- Skeleton_Warrior 131.0u
            {-29.000, -60.830, -219.000,  26 },   -- Skeleton_Warrior 142.8u
            {-47.130, -60.040, -218.820,  57 },   -- Ghoul            153.3u
            { 62.000, -59.480, -186.000, 127 },   -- Fly_Agaric       155.1u
            {-55.780, -60.970, -223.590,  21 },   -- Ghoul            155.1u
            { 69.590, -59.700, -181.620, 127 },   -- Fly_Agaric       160.3u
            { 13.000, -59.000, -183.000,  18 },   -- Skeleton_Warrior 160.8u
            { 56.340, -59.620, -178.880, 127 },   -- Fly_Agaric       161.7u
            { 63.000, -59.670, -176.000, 127 },   -- Fly_Agaric       165.1u
            {-16.710, -59.780, -186.030,  66 },   -- Grieving Spirit boss 166.6u
        }, 'Gusgen Skeleton', 'Gusgen Hound', 'Grieving Spirit', 8),
        -- Cluster is ~118-167u from entry (Gusgen entry sits in a north
        -- alcove disconnected from the mob chamber). Leash 180u encloses the
        -- whole cluster + a bit of margin so the walk from entry to first
        -- mob doesn't get snapped back constantly.
        leash = 180,
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
            -- Roster fully rebuilt from retail zone-174 stock spawn coords
            -- (2026-07-13, Lant's "1 mob spawned inside the wall" report).
            -- Every coord below is verbatim from sql/mob_spawn_points.sql --
            -- guaranteed walkable navmesh. Sorted by distance from entry.
            { 57.000, -10.000, 260.000,  19 },   -- Robber_Crab      12.6u
            { 53.600, -11.840, 251.390, 127 },   -- Robber_Crab      13.0u
            { 60.400, -10.360, 252.210, 127 },   -- Robber_Crab      17.9u
            { 61.790, -10.450, 244.350,  21 },   -- Robber_Crab      23.6u
            { 79.000, -10.000, 220.000,  39 },   -- Robber_Crab      53.1u
            { 69.110, -11.540, 209.400, 127 },   -- Robber_Crab      56.6u
            { 91.000,  -9.000, 220.000, 127 },   -- Robber_Crab      61.6u
            { 60.910,  -9.030, 198.390, 127 },   -- Fire_Elemental   64.1u
            { 55.520,  -6.610, 190.470, 127 },   -- Cave_Worm        70.8u
            { 100.000, -9.000, 215.000, 127 },   -- Robber_Crab      71.7u
            { 61.000,  -5.000, 185.000, 127 },   -- Cave_Worm        77.3u
            { 97.550, -10.380, 202.470, 127 },   -- Robber_Crab      78.6u
            { 59.630,  -3.670, 180.910,  22 },   -- Needleback boss  81.1u
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
            -- Roster fully rebuilt from retail zone-212 stock spawn coords
            -- (2026-07-13, Lant's "1 mob + boss inside wall" report). Every
            -- coord verbatim from sql/mob_spawn_points.sql. Cluster follows the
            -- tunnel from Y=-33 down and up to Y=-10 as it ramps -- Y=+10
            -- cavern excluded (unreachable perpendicular level).
            { 334.000, -33.000,  53.000, 118 },   -- Hell_Bat          37.8u
            { 300.000, -25.000,  21.000, 100 },   -- Hell_Bat          51.1u
            { 323.000, -30.880,  20.000, 127 },   -- Hell_Bat          55.3u
            { 278.260, -20.610,  20.820, 127 },   -- Hell_Bat          57.4u
            { 259.000, -18.000,   1.000, 127 },   -- Goblin_Reaper     83.6u
            { 261.060, -19.390,  -7.420, 127 },   -- Hawker            89.4u
            { 245.000, -19.000, -20.000, 127 },   -- Goblin_Poacher   107.9u
            { 238.000, -18.000, -19.000, 127 },   -- Hawker           111.1u
            { 216.000, -20.000, -21.000, 127 },   -- Hawker           126.0u
            { 176.950, -11.420, -28.130, 104 },   -- Goblin_Robber    160.6u
            { 164.000, -10.000, -39.000,  28 },   -- Hawker           177.5u
            { 158.290, -10.660, -36.630,  75 },   -- Goblin_Robber    180.4u
            { 158.260, -10.840, -39.340, 127 },   -- Ironclaw boss    182.0u
        }, 'Gustav Bat', 'Gustav Fly', 'Ironclaw', 8),
        -- Boss ~182u from entry (natural tunnel ramp end); per-dungeon leash
        -- 200u to keep player chasing the boss inside the bubble.
        leash = 200,
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
            -- Roster fully rebuilt from retail zone-204 stock spawn coords
            -- (2026-07-13, Lant + Jamesta reports: players running the wrong
            -- way get pulled back into a dead-end room, can't reach the mobs
            -- in the next hallway). Prior roster spanned z=18..111 -- boss at
            -- z=+58 was 33u from the entry cluster, past the default 55u
            -- leash bubble, so players who chased west-arm mobs got snapped
            -- back to entry and couldn't reach them again. New roster is 13
            -- unique upper-level (Y ~ 0) stock points across three arms
            -- (tight core, east arm, west arm), per-dungeon leash raised to
            -- 65u to keep the whole cluster inside the bubble. All coords
            -- verbatim from stock; NO lower-level (Y=-16) points -- those
            -- required an unreachable ramp and were the dead-end trap.
            { -62.330, -0.500, 19.030,  10 },   -- Talos            5.7u
            { -47.990, -0.110, 21.130,   3 },   -- Underworld_Bats  9.0u
            { -51.190, -0.020, 32.210, 251 },   -- Talos           12.6u
            { -49.720, -0.110,  5.450, 104 },   -- Talos           17.2u
            { -71.840, -0.110, 30.040, 129 },   -- Talos           17.4u
            { -87.660, -0.110, 20.640, 245 },   -- Underworld_Bats 30.7u
            {  -3.780, -0.130, 28.430,  18 },   -- Droma           53.7u
            {-100.500, -0.110, 54.800, 196 },   -- Underworld_Bats 55.1u
            {  -4.410,  0.340, 40.530, 246 },   -- Camazotz        56.1u
            { -91.150, -0.500, 68.630,  37 },   -- Killing_Weapon  58.6u
            {   1.870, -0.120, 27.340,  10 },   -- Droma           59.2u
            { -90.740, -0.030, 70.510, 196 },   -- Hellish_Weapon  59.9u
            { -90.000, -0.110, 72.000,  37 },   -- Frostmaw Morbol boss 60.7u
        }, "Fei'Yin Golem", "Fei'Yin Pot", 'Frostmaw Morbol', 8),
        -- Boss 60.7u from entry (west arm end); leash 65u encloses it with
        -- ~4u of margin. All 13 mobs on the upper level so no cross-level
        -- ramping / dead-end trap.
        leash = 65,
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
