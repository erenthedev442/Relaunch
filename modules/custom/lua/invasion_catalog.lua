-----------------------------------
-- invasion_catalog.lua
-- Config for the Invasion system (see Invasion.lua).
--
-- Twice a day at fixed UTC times, the Voidsent assault GM Home - the
-- moogles' sanctuary and the server's social hub. Every defender
-- present fights waves that scale with attendance; clear all waves
-- (including the Warlord) before the clock runs out and everyone
-- present is paid in marks + Infamy.
--
-- The event only fires when at least one player is standing in the
-- zone during the window (grace period below) - an invasion with no
-- defenders just doesn't happen, and the day's window stays burned so
-- it can't be re-triggered.
-----------------------------------
local catalog = {}

-- Battleground: the hub. Spawns ring around DEFENDERS (never fixed
-- coords), so the zone's geometry can't strand a mob off-map.
catalog.zone   = 'GM_Home'
catalog.zoneId = 210

-- HL mob groups are registered under this zone id (hunting_league_
-- gm_home_mobs.sql), resolvable by the engine for spawns here.
catalog.groupZoneId = 210

-- ============================================================
-- SCHEDULE (UTC)
-- ============================================================
-- Two windows daily. 23:00 UTC = 7pm EDT / 6pm EST; 01:00 UTC = 9pm
-- EDT / 8pm EST. Each window fires at most once per UTC day.
catalog.windows =
{
    { hour = 23, min = 0 },
    { hour =  1, min = 0 },
}

catalog.warnMinutes  = 5    -- server-wide warning this many minutes before
catalog.graceMinutes = 10   -- window stays armed this long waiting for a defender
catalog.tickSeconds  = 30   -- clock granularity (per-player re-arming timer)

-- ============================================================
-- WAVES
-- ============================================================
-- count = base + perDefender * (#players in zone at wave start).
-- Levels ride the HL stat templates; mods below keep them punchy.
-- The final wave adds the Warlord on top of its trash.
catalog.interWaveDelaySec = 8
catalog.timeLimitSec      = 900   -- 15 minutes for the full assault

catalog.waves =
{
    {
        label = 'Vanguard', level = 110, base = 3, perDefender = 2,
        groups = { 11355, 11357 }, names = { 'Voidsent Raider', 'Voidsent Skirmisher' },
        mods = { [xi.mod.ATT] = 1400, [xi.mod.ACC] = 640, [xi.mod.HASTE_GEAR] = 75 },
        hpMult = 1.8,
    },
    {
        label = 'Shock Troops', level = 125, base = 3, perDefender = 2,
        groups = { 11359, 11361 }, names = { 'Voidsent Marauder', 'Voidsent Impaler' },
        mods = { [xi.mod.ATT] = 1900, [xi.mod.ACC] = 740, [xi.mod.HASTE_GEAR] = 100, [xi.mod.DOUBLE_ATTACK] = 6 },
        hpMult = 2.2,
    },
    {
        label = 'Dreadguard', level = 140, base = 3, perDefender = 2,
        groups = { 11362, 11363 }, names = { 'Voidsent Ravager', 'Voidsent Dreadknight' },
        mods = { [xi.mod.ATT] = 2400, [xi.mod.ACC] = 860, [xi.mod.HASTE_GEAR] = 140, [xi.mod.DOUBLE_ATTACK] = 9 },
        hpMult = 2.6,
    },
    {
        label = 'The Warlord', level = 155, base = 2, perDefender = 1,
        groups = { 11364, 11366 }, names = { 'Voidsent Houndmaster', 'Voidsent Banneret' },
        mods = { [xi.mod.ATT] = 2900, [xi.mod.ACC] = 980, [xi.mod.HASTE_GEAR] = 170, [xi.mod.DOUBLE_ATTACK] = 11 },
        hpMult = 3.0,
        boss = {
            name = 'Voidsent Warlord', level = 165, group = 11368,
            mods = { [xi.mod.ATT] = 3400, [xi.mod.ACC] = 1060, [xi.mod.HASTE_GEAR] = 200, [xi.mod.DOUBLE_ATTACK] = 13 },
            hpMult = 7.0,
            modelSize = 3,    -- render huge - it IS the event
        },
    },
}

-- Spawn ring around a (random) defender, yalms.
catalog.spawnRingMin = 10.0
catalog.spawnRingMax = 14.0

-- ============================================================
-- REWARDS
-- ============================================================
-- Paid to every participant still in the zone at the relevant moment.
-- A participant is anyone present at ANY wave start.
catalog.reward =
{
    perWaveMarks  = 100,   -- on each wave clear
    victoryMarks  = 400,   -- on full clear, plus...
    victoryInfamy = 150,   -- ...the only Infamy source outside dungeons (intentional)
    failMarks     = 50,    -- consolation if the clock beats the defense
}

return catalog
