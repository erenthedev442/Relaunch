-----------------------------------
-- colosseum_catalog.lua
-- Config for the Colosseum (see Colosseum.lua) - async ranked PvP.
--
-- Players ENROLL a champion at the Arena Herald (GM Home). Enrolling
-- snapshots identity (name / race / job / level) into SERVER variables
-- so other players can fight an AI REPLICA of the champion any time,
-- online or not. Ratings are Elo: beat a replica and YOUR rating rises
-- while THEIR ladder rating drops (the asynchronous duel cuts both
-- ways), so the ladder stays zero-sum and self-balancing.
--
-- Replica difficulty scales with the CHAMPION'S RATING, not their gear
-- (Lua can't read another character's equipment) - a high rating IS
-- the proof of a dangerous champion. Climbing the ladder literally
-- makes your champion harder to beat.
--
-- Storage map (server variables, int-only):
--   [Col]Count            roster slots used (monotonic)
--   [Col]Roster_<i>       charid in roster slot i (1..Count)
--   [Col]Idx_<charid>     roster slot for charid (0 = never enrolled)
--   [Col]On_<charid>      1 = enrolled/listed, 0 = retired
--   [Col]Rt_<charid>      current Elo rating
--   [Col]Race_<charid>    xi.race id (replica model)
--   [Col]Job_<charid>     main job id at enroll time (flavor)
--   [Col]Lvl_<charid>     main level at enroll time (flavor)
--   [Col]Nm_<charid>_1..4 name, packed 4 ASCII chars per int
-- Per-player charvars (own ratings mirrored for the website boards):
--   Col_Rating, Col_Best_Rating, Col_Wins, Col_Losses,
--   Col_LastDay_<oppCharid> (per-opponent daily-limit stamp)
-----------------------------------
local catalog = {}

-- Arena Herald placement - GM Home Activities cluster (z=-21 row):
-- ExpCamp / Weekly Hunts / Dungeon Master (1.5) / Infamy Vendor (4.5)
-- / Arena Herald (7.5).
catalog.npcPos =
{
    zone     = 'GM_Home',
    zoneId   = 210,
    x        =  1.500,
    y        =  0.000,
    z        = -25.000,
    rotation =  128,
}

-- Duels may only be fought in this zone (the replica spawns relative
-- to the player, so the hub's flat geometry is load-bearing).
catalog.arenaZoneId = 210

-- ============================================================
-- ELO LADDER
-- ============================================================
catalog.elo =
{
    start = 1200,   -- every champion enters here
    k     = 32,     -- volatility; standard chess K
    floor = 800,    -- ratings can't sink below this (keeps replicas beatable)
}

-- ============================================================
-- REPLICA SCALING (rating -> mob stats)
-- ============================================================
-- Level: 99 at rating<=1000, +1 level per `levelPerRating` rating above
-- that, hard-capped at 205 (past there mob acc/eva outruns L99 gear -
-- same engine lesson as the Voidspire).
catalog.replica =
{
    groupId      = 11361,  -- HL Serket group (registered in zone 210); the
                           -- model is overridden to the champion's race below
    groupZoneId  = 210,
    levelBase    = 99,
    ratingBase   = 1000,
    levelPerRating = 10,   -- +1 level per 10 rating above ratingBase
    levelCap     = 205,

    -- HP multiplier: base + (rating - 1200)/hpRatingDiv, clamped.
    hpBase      = 3.0,
    hpRatingDiv = 200,     -- +1.0x per 200 rating above 1200
    hpMin       = 2.0,
    hpMax       = 10.0,

    -- Combat mod profile by replica level (linear interpolation between
    -- rows; flat beyond the ends). Tuned against the dungeon levelMods
    -- ladder so a replica feels like a boss-grade mob of its level.
    modRows =
    {
        { level =  99, mods = { [xi.mod.ATT] = 1100, [xi.mod.ACC] =  600, [xi.mod.STR] =  45, [xi.mod.DEX] =  45, [xi.mod.HASTE_GEAR] =  60, [xi.mod.DOUBLE_ATTACK] =  4 } },
        { level = 120, mods = { [xi.mod.ATT] = 1900, [xi.mod.ACC] =  750, [xi.mod.STR] =  75, [xi.mod.DEX] =  75, [xi.mod.HASTE_GEAR] = 110, [xi.mod.DOUBLE_ATTACK] =  7 } },
        { level = 140, mods = { [xi.mod.ATT] = 2400, [xi.mod.ACC] =  880, [xi.mod.STR] =  95, [xi.mod.DEX] =  95, [xi.mod.HASTE_GEAR] = 140, [xi.mod.DOUBLE_ATTACK] =  9 } },
        { level = 160, mods = { [xi.mod.ATT] = 2900, [xi.mod.ACC] = 1000, [xi.mod.STR] = 115, [xi.mod.DEX] = 115, [xi.mod.HASTE_GEAR] = 170, [xi.mod.DOUBLE_ATTACK] = 11 } },
        { level = 180, mods = { [xi.mod.ATT] = 3400, [xi.mod.ACC] = 1120, [xi.mod.STR] = 135, [xi.mod.DEX] = 135, [xi.mod.HASTE_GEAR] = 200, [xi.mod.DOUBLE_ATTACK] = 13 } },
        { level = 205, mods = { [xi.mod.ATT] = 4000, [xi.mod.ACC] = 1250, [xi.mod.STR] = 160, [xi.mod.DEX] = 160, [xi.mod.HASTE_GEAR] = 230, [xi.mod.DOUBLE_ATTACK] = 15 } },
    },

    -- Spawn ring around the player (yalms) - geometry-safe anywhere.
    spawnRingMin = 8.0,
    spawnRingMax = 11.0,
    modelSize    = 0,      -- champions are player-sized
}

-- ============================================================
-- DUEL RULES
-- ============================================================
catalog.duel =
{
    countdownSec    = 3,    -- breather between accepting and the spawn
    timeLimitSec    = 300,  -- 5 minutes, then the duel is forfeit
    watchdogSec     = 5,    -- replica-side check that the player is still here
    perOpponentPerDay = true,  -- each champion can be challenged once per UTC day
}

-- ============================================================
-- REWARDS (Hunt Marks - the server's main currency)
-- ============================================================
catalog.reward =
{
    winBase      = 150,   -- flat marks per ladder win
    underdogDiv  = 4,     -- + (oppRating - myRating)/this when punching up
    lossMarks    = 25,    -- consolation marks on a loss
}

-- Roster menu pagination. Rows are "Name R1234" (<= ~22 bytes); 3 rows
-- + nav + title stays inside the 150-byte customMenu budget.
catalog.rosterPageSize = 3

return catalog
