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
    zone     = 'Abdhaljs_Isle-Purgonorgo',
    zoneId   = 44,
    x        = 523.000,
    y        =  -3.000,
    z        = 580.000,
    rotation =  190,
}

-- How many objectives per day.
catalog.slotsPerDay = 3

-- Meta-reward when all 3 are cleared in a single calendar day.
catalog.allClearedReward =
{
    rewards  = {
        { currency = 'hl', amount = 500 },
        { currency = 'af', amount = 100 },
    },
    titleCv  = 'DB_AllCleared_Lifetime',
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
    infamy   = 'Infamy_Lifetime',
    waves    = 'Wave_Clears_Total',
    augments = 'Augment_Count',
}

-- CharVar suffixes used internally.
catalog.cvDay         = 'DB_Day'          -- Julian day YYYYDDD of last reset
catalog.cvKillsBase   = 'DB_Kills_Base'
catalog.cvInfamyBase  = 'DB_Infamy_Base'
catalog.cvWavesBase   = 'DB_Waves_Base'
catalog.cvAugmentsBase= 'DB_Augments_Base'

-- =========================================================
-- CURRENCY MAPPING
-- =========================================================
-- Must match the mapping in weekly_hunts_catalog.lua.
catalog.currencies =
{
    hl   = { cv = 'HL_Points',      name = 'Hunt Marks'    },
    af   = { cv = 'RF_AF_Marks',    name = 'AF Marks'      },
    relic= { cv = 'RF_Relic_Marks', name = 'Relic Marks'   },
    empy = { cv = 'RF_Empy_Marks',  name = 'Empy Marks'    },
}

-- =========================================================
-- OBJECTIVE POOL
-- =========================================================
-- Each entry:
--   id          unique string
--   label       short display name (<= 16 chars to fit customMenu)
--   description one-liner shown in the NPC menu
--   target      numeric completion threshold
--   metric      which baseline to measure against: 'kills' | 'infamy' | 'waves' | 'augments'
--   reward      { currency = 'hl'|'af'|'relic'|'empy', amount = N }
--
-- Rotation guarantees that only ONE entry per metric appears
-- in any given day's 3 slots, so the board always has variety.
catalog.objectivePool =
{
    -- --- KILLS ------------------------------------------------
    {
        id          = 'kill_5',
        label       = 'NM Slayer',
        description = 'Kill 5 custom NMs today (any system).',
        target      = 5,
        metric      = 'kills',
        reward      = { currency = 'hl', amount = 400 },
    },
    {
        id          = 'kill_10',
        label       = 'NM Veteran',
        description = 'Kill 10 custom NMs today (any system).',
        target      = 10,
        metric      = 'kills',
        reward      = { currency = 'hl', amount = 1000 },
    },
    {
        id          = 'kill_20',
        label       = 'NM Rampage',
        description = 'Kill 20 custom NMs today (any system).',
        target      = 20,
        metric      = 'kills',
        reward      = { currency = 'relic', amount = 1500 },
    },

    -- --- INFAMY ------------------------------------------------
    {
        id          = 'infamy_50',
        label       = 'Infamy Earner',
        description = 'Earn 50 Infamy today.',
        target      = 50,
        metric      = 'infamy',
        reward      = { currency = 'hl', amount = 400 },
    },
    {
        id          = 'infamy_100',
        label       = 'Infamy Collector',
        description = 'Earn 100 Infamy today.',
        target      = 100,
        metric      = 'infamy',
        reward      = { currency = 'hl', amount = 900 },
    },
    {
        id          = 'infamy_250',
        label       = 'Infamy Hoarder',
        description = 'Earn 250 Infamy today.',
        target      = 250,
        metric      = 'infamy',
        reward      = { currency = 'empy', amount = 1200 },
    },

    -- --- WAVE FIGHTS ------------------------------------------
    {
        id          = 'wave_1',
        label       = 'Wave Warrior',
        description = 'Win 1 wave fight today (any difficulty).',
        target      = 1,
        metric      = 'waves',
        reward      = { currency = 'hl', amount = 700 },
    },
    {
        id          = 'wave_2',
        label       = 'Wave Runner',
        description = 'Win 2 wave fights today.',
        target      = 2,
        metric      = 'waves',
        reward      = { currency = 'relic', amount = 850 },
    },
    {
        id          = 'wave_3',
        label       = 'Wave Dominator',
        description = 'Win 3 wave fights today.',
        target      = 3,
        metric      = 'waves',
        reward      = { currency = 'empy', amount = 1100 },
    },

    -- --- AUGMENTS ----------------------------------------------
    {
        id          = 'augment_1',
        label       = 'Forgemaster',
        description = 'Complete 1 augmentation trade today.',
        target      = 1,
        metric      = 'augments',
        reward      = { currency = 'hl', amount = 400 },
    },
    {
        id          = 'augment_2',
        label       = 'Augment Artisan',
        description = 'Complete 2 augmentation trades today.',
        target      = 2,
        metric      = 'augments',
        reward      = { currency = 'hl', amount = 700 },
    },
    {
        id          = 'augment_3',
        label       = 'Augment Adept',
        description = 'Complete 3 augmentation trades today.',
        target      = 3,
        metric      = 'augments',
        reward      = { currency = 'af', amount = 1200 },
    },
}

return catalog
