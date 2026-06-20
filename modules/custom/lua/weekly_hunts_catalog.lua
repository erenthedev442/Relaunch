-----------------------------------
-- weekly_hunts_catalog.lua
--
-- Config for the Weekly Hunt Board. Players get 5 random objectives
-- rolled per week (from a larger pool). Completing each pays a bonus,
-- clearing ALL 5 pays a meta-bonus + title.
--
-- Resets every Monday 00:00 UTC (ISO week). A player's first
-- interaction in a new week auto-rolls a fresh objective set.
-----------------------------------
local catalog = {}

-- GM Home Activities cluster (z=-21): ExpCamp / Weekly Hunts /
-- Dungeon Master / Infamy Vendor.
catalog.npcPos =
{
    zone     = 'GM_Home',
    zoneId   = 210,
    x        = -1.500,
    y        =  0.000,
    z        = -25.000,
    rotation =  128,
}

-- How many objectives are active per week (rolled from the pool).
catalog.slotsPerWeek = 5

-- Reward paid when ALL slotsPerWeek objectives are cleared in one week.
-- Title flag is a CharVar set to lifetime-count of "all-cleared" weeks
-- so the player has a permanent record of consistency.
catalog.allClearedReward =
{
    currency = 'hl',
    amount   = 5000,
    titleCv  = 'WH_AllCleared_Lifetime',
}

-- =========================================================
-- OBJECTIVE POOL
-- =========================================================
-- Each entry:
--   id          : stable string ID (for logs / docs)
--   label       : short menu name
--   description : one-line text in NPC menu
--   target      : numeric goal (counter type)
--   eventType   : which event this objective listens for
--                 (see weekly_hunts.fire callers below)
--   matches     : function(metadata) -> bool - does this event count
--                 toward this objective? defaults to "yes always".
--   reward      : { currency = 'hl'|'af'|'relic'|'empy', amount = N }
--
-- The pool can grow over time without code changes - just append rows.
-- The roller picks slotsPerWeek unique entries randomly.
catalog.objectivePool =
{
    {
        id          = 'slay_25',
        label       = 'NM Slayer',
        description = 'Kill 25 custom NMs this week (any system).',
        target      = 25,
        eventType   = 'nm_kill',
        reward      = { currency = 'hl', amount = 1500 },
    },
    {
        id          = 'apex_5',
        label       = 'Apex Hunter',
        description = 'Slay 5 Lv250 apex NMs this week.',
        target      = 5,
        eventType   = 'nm_kill',
        matches     = function(meta) return (meta and meta.level or 0) >= 250 end,
        reward      = { currency = 'af', amount = 2000 },
    },
    {
        id          = 'guild_rankup',
        label       = 'Guild Climber',
        description = 'Earn one Hunter\'s Guild rank-up this week.',
        target      = 1,
        eventType   = 'guild_rankup',
        reward      = { currency = 'hl', amount = 1000 },
    },
    {
        id                = 'wave_clear',
        label             = 'Wave Master',
        description       = 'Complete a GM wave session, OR kill 20 custom NMs this week.',
        target            = 1,
        eventType         = 'gm_wave_clear',
        alternateEventType = 'nm_kill',
        alternateTarget   = 20,
        reward            = { currency = 'hl', amount = 1000 },
    },
    {
        id          = 'augment_10',
        label       = 'Sage\'s Hand',
        description = 'Successfully augment 10 items this week.',
        target      = 10,
        eventType   = 'augment_done',
        reward      = { currency = 'hl', amount = 500 },
    },
    {
        id          = 'reforge_10',
        label       = 'Reforge Devotee',
        description = 'Kill 10 Reforge NMs this week (any set).',
        target      = 10,
        eventType   = 'nm_kill',
        matches     = function(meta) return meta and meta.system == 'reforge' end,
        reward      = { currency = 'af', amount = 1000 },
    },
    {
        id          = 'hl_10',
        label       = 'League Devotee',
        description = 'Kill 10 Hunting League NMs this week.',
        target      = 10,
        eventType   = 'nm_kill',
        matches     = function(meta) return meta and meta.system == 'hl' end,
        reward      = { currency = 'hl', amount = 1000 },
    },
    {
        id          = 'midtier_15',
        label       = 'Climbing Force',
        description = 'Kill 15 Lv175+ NMs this week.',
        target      = 15,
        eventType   = 'nm_kill',
        matches     = function(meta) return (meta and meta.level or 0) >= 175 end,
        reward      = { currency = 'relic', amount = 1500 },
    },
    {
        id          = 'party_10',
        label       = 'Pack Hunter',
        description = 'Slay 10 NMs while partied with another player.',
        target      = 10,
        eventType   = 'nm_kill',
        matches     = function(meta) return (meta and meta.partySize or 1) >= 2 end,
        reward      = { currency = 'hl', amount = 1500 },
    },
    {
        id          = 'speed_apex',
        label       = 'Speed Demon',
        description = 'Kill an apex (Lv250) NM within 60 seconds of its spawn.',
        target      = 1,
        eventType   = 'nm_kill',
        matches     = function(meta)
            return (meta and meta.level or 0) >= 250
               and (meta and meta.secondsToKill or 9999) <= 60
        end,
        reward      = { currency = 'empy', amount = 2000 },
    },
    {
        id          = 'streak_15',
        label       = 'Untouchable',
        description = 'Kill 15 custom NMs in a row without dying.',
        target      = 15,
        eventType   = 'nm_kill',
        -- Max-aggregator: progress = best streak seen this week, not
        -- a counter. The metadata.killStreak field is incremented by
        -- weekly_hunts.fire() on every nm_kill event and reset to 0
        -- by the onPlayerDeath override (also in weekly_hunts.lua).
        progressFn = function(meta, current)
            local streak = (meta and meta.killStreak) or 0
            if streak > current then return streak end
            return current
        end,
        reward      = { currency = 'hl', amount = 2500 },
    },
}

-- =========================================================
-- CURRENCY MAPPING
-- =========================================================
-- Map from internal currency code -> CharVar to credit + display name.
-- Used when paying out objective rewards.
catalog.currencyCv =
{
    hl    = { cv = 'HL_Points',      label = 'Hunt Marks'  },
    af    = { cv = 'RF_AF_Marks',    label = 'AF Marks'    },
    relic = { cv = 'RF_Relic_Marks', label = 'Relic Marks' },
    empy  = { cv = 'RF_Empy_Marks',  label = 'Empy Marks'  },
}

return catalog
