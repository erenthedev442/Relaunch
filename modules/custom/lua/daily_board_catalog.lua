-----------------------------------
-- daily_board_catalog.lua
--
-- Config for the Daily Board system (see daily_board.lua).
-- Players get 3 objectives per day that rotate deterministically
-- (same day = same objectives for every player on the server).
-- Progress is snapshot-based: baselines are recorded on first
-- NPC talk of the day, then compared to current CharVars on return.
-- No event hooks in other modules needed.
--
-- To add a new objective: append a row to objectivePool.
-- Objectives that share the same `metric` never appear together
-- in the same day's 3 slots (prevents "kill 5 NMs" and "kill 10
-- NMs" showing up on the same board). Rotation logic is in daily_board.lua.
-----------------------------------
local catalog = {}

-- GM Home Activities cluster. Place the Daily Board NPC west of the
-- existing cluster (ExpCamp is at x=-4.5, Hunt Board at x=-1.5;
-- this goes to x=-7.5 to continue the row westward).
catalog.npcPos =
{
    zone     = 'GM_Home',
    zoneId   = 210,
    x        = -7.500,
    y        =  0.000,
    z        = -21.000,
    rotation =  128,
}

-- How many objectives per day.
catalog.slotsPerDay = 3

-- Meta-reward when all 3 are cleared in a single calendar day.
catalog.allClearedReward =
{
    currency  = 'hl',
    amount    = 1000,
    titleCv   = 'DB_AllCleared_Lifetime',
}

-- =========================================================
-- SNAPSHOT BASELINES
-- =========================================================
-- CharVars that track lifetime totals in other systems.
-- Daily Board snapshots these on a player's first NPC visit
-- each day, then measures progress = current - snapshot.
catalog.baselines =
{
    kills    = 'Custom_NM_Kills',
    dungeons = 'Dungeon_Clears_Total',
    infamy   = 'Infamy_Lifetime',
}

-- CharVar suffixes used internally.
catalog.cvDay         = 'DB_Day'          -- Julian day YYYYDDD of last reset
catalog.cvKillsBase   = 'DB_Kills_Base'
catalog.cvDungeonsBase= 'DB_Dungeons_Base'
catalog.cvInfamyBase  = 'DB_Infamy_Base'

-- =========================================================
-- CURRENCY MAPPING
-- =========================================================
-- Must match the mapping in weekly_hunts_catalog.lua.
catalog.currencies =
{
    hl   = { cv = 'HL_Points',    name = 'Hunt Marks'    },
    af   = { cv = 'AF_Points',    name = 'AF Marks'      },
    relic= { cv = 'Relic_Points', name = 'Relic Marks'   },
    empy = { cv = 'Empy_Points',  name = 'Empy Marks'    },
}

-- =========================================================
-- OBJECTIVE POOL
-- =========================================================
-- Each entry:
--   id          unique string
--   label       short display name (≤ 16 chars to fit customMenu)
--   description one-liner shown in the NPC menu
--   target      numeric completion threshold
--   metric      which baseline to measure against: 'kills' | 'dungeons' | 'infamy'
--   reward      { currency = 'hl'|'af'|'relic'|'empy', amount = N }
--
-- Rotation guarantees that only ONE entry per metric appears
-- in any given day's 3 slots, so the board always has variety.
catalog.objectivePool =
{
    -- ─── KILLS ────────────────────────────────────────────────
    {
        id          = 'kill_5',
        label       = 'NM Slayer',
        description = 'Kill 5 custom NMs today (any system).',
        target      = 5,
        metric      = 'kills',
        reward      = { currency = 'hl', amount = 500 },
    },
    {
        id          = 'kill_10',
        label       = 'NM Veteran',
        description = 'Kill 10 custom NMs today (any system).',
        target      = 10,
        metric      = 'kills',
        reward      = { currency = 'hl', amount = 800 },
    },
    {
        id          = 'kill_20',
        label       = 'NM Rampage',
        description = 'Kill 20 custom NMs today (any system).',
        target      = 20,
        metric      = 'kills',
        reward      = { currency = 'af', amount = 1000 },
    },

    -- ─── DUNGEONS ──────────────────────────────────────────────
    {
        id          = 'dungeon_1',
        label       = 'Dungeon Diver',
        description = 'Clear any dungeon today.',
        target      = 1,
        metric      = 'dungeons',
        reward      = { currency = 'hl', amount = 750 },
    },
    {
        id          = 'dungeon_2',
        label       = 'Twin Diver',
        description = 'Clear 2 dungeon runs today (any combination).',
        target      = 2,
        metric      = 'dungeons',
        reward      = { currency = 'relic', amount = 1200 },
    },
    {
        id          = 'dungeon_3',
        label       = 'Triple Diver',
        description = 'Clear 3 dungeon runs today.',
        target      = 3,
        metric      = 'dungeons',
        reward      = { currency = 'empy', amount = 1500 },
    },

    -- ─── INFAMY ────────────────────────────────────────────────
    {
        id          = 'infamy_50',
        label       = 'Infamy Earner',
        description = 'Earn 50 Infamy from dungeons today.',
        target      = 50,
        metric      = 'infamy',
        reward      = { currency = 'hl', amount = 400 },
    },
    {
        id          = 'infamy_100',
        label       = 'Infamy Collector',
        description = 'Earn 100 Infamy from dungeons today.',
        target      = 100,
        metric      = 'infamy',
        reward      = { currency = 'hl', amount = 700 },
    },
    {
        id          = 'infamy_250',
        label       = 'Infamy Hoarder',
        description = 'Earn 250 Infamy from dungeons today.',
        target      = 250,
        metric      = 'infamy',
        reward      = { currency = 'relic', amount = 1000 },
    },
}

return catalog
