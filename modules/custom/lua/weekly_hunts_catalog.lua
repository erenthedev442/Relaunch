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
    zone     = 'Abdhaljs_Isle-Purgonorgo',
    zoneId   = 44,
    x        = 515.5119,
    y        =  -3.1516,
    z        = 520.0237,
    rotation =  192,
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
--   minHLRank   : Hunting League rank (HL_Tier, 1-5) required to make
--                 progress on this objective. Below it the objective is
--                 LOCKED - events don't count - so the all-5 sweep bonus
--                 (5,000 marks) is gated behind real HL progression rather
--                 than being clearable week 1. Defaults to 1 if omitted.
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
        minHLRank   = 2,
        label       = 'NM Slayer',
        description = 'Kill 25 custom NMs this week (any system).',
        target      = 25,
        eventType   = 'nm_kill',
        reward      = { currency = 'hl', amount = 1500 },
    },
    {
        id          = 'apex_5',
        minHLRank   = 5,
        label       = 'Apex Hunter',
        description = 'Slay 5 Lv250 apex NMs this week.',
        target      = 5,
        eventType   = 'nm_kill',
        matches     = function(meta) return (meta and meta.level or 0) >= 250 end,
        reward      = { currency = 'af', amount = 2000 },
    },
    {
        id          = 'guild_rankup',
        minHLRank   = 1,
        label       = 'Guild Climber',
        description = 'Earn one Hunter\'s Guild rank-up this week.',
        target      = 1,
        eventType   = 'guild_rankup',
        reward      = { currency = 'hl', amount = 1000 },
    },
    {
        id                = 'wave_clear',
        minHLRank          = 2,
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
        minHLRank   = 3,
        label       = 'Sage\'s Hand',
        description = 'Successfully augment 10 items this week.',
        target      = 10,
        eventType   = 'augment_done',
        reward      = { currency = 'hl', amount = 500 },
    },
    {
        id          = 'reforge_10',
        minHLRank   = 3,
        label       = 'Reforge Devotee',
        description = 'Kill 10 Reforge NMs this week (any set).',
        target      = 10,
        eventType   = 'nm_kill',
        matches     = function(meta) return meta and meta.system == 'reforge' end,
        reward      = { currency = 'af', amount = 1000 },
    },
    {
        id          = 'hl_10',
        minHLRank   = 2,
        label       = 'League Devotee',
        description = 'Kill 10 Hunting League NMs this week.',
        target      = 10,
        eventType   = 'nm_kill',
        matches     = function(meta) return meta and meta.system == 'hl' end,
        reward      = { currency = 'hl', amount = 1000 },
    },
    {
        id          = 'midtier_15',
        minHLRank   = 3,
        label       = 'Climbing Force',
        description = 'Kill 15 Lv175+ NMs this week.',
        target      = 15,
        eventType   = 'nm_kill',
        matches     = function(meta) return (meta and meta.level or 0) >= 175 end,
        reward      = { currency = 'relic', amount = 1500 },
    },
    {
        id          = 'party_10',
        minHLRank   = 2,
        label       = 'Pack Hunter',
        description = 'Slay 10 NMs while partied with another player.',
        target      = 10,
        eventType   = 'nm_kill',
        matches     = function(meta) return (meta and meta.partySize or 1) >= 2 end,
        reward      = { currency = 'hl', amount = 1500 },
    },
    {
        id          = 'speed_apex',
        minHLRank   = 5,
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
        minHLRank   = 2,
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
