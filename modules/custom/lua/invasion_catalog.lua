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

-- Battleground: Al Zahbi. Spawns ring around DEFENDERS (never fixed
-- coords), so the zone's geometry can't strand a mob off-map.
catalog.zone   = 'Al_Zahbi'
catalog.zoneId = 48

-- Mob groups are still registered under zone 210 (GM_Home) in the DB.
-- groupZoneId tells the engine where to look up the group definitions.
catalog.groupZoneId = 210

-- ============================================================
-- SCHEDULE (UTC)
-- ============================================================
-- Every 3 hours. Each window fires at most once per UTC day.
catalog.windows =
{
    { hour =  0, min = 0 },
    { hour =  3, min = 0 },
    { hour =  6, min = 0 },
    { hour =  9, min = 0 },
    { hour = 12, min = 0 },
    { hour = 15, min = 0 },
    { hour = 18, min = 0 },
    { hour = 21, min = 0 },
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
    perWaveMarks  = 1200,  -- on each wave clear (x4 waves = 4800 across a full assault)
    victoryMarks  = 9000,  -- on full clear (the Warlord falls), plus...
    victoryInfamy = 2400,  -- ...the only Infamy source outside dungeons (intentional)
    failMarks     = 1200,  -- consolation if the clock beats the defense

    -- Gear-vendor seal loot on a WIN -- ties the invasion into the Armor /
    -- Weapons NPC gear loop (!hunt). Seals stack to 99 (stackable_medals.sql).
    -- This is the "feels like loot" reward; these two lines are the main
    -- economy levers, tune freely:
    --   9541 Kindreds Medal = SILVER currency (mid gear, ~25 medals/piece)
    --   9543 Demons Medal   = GOLD  currency (BiS gear, 50-500 medals/piece)
    victorySeals    = { { id = 9541, qty = 12, name = 'Kindreds Medal' } },              -- guaranteed
    victoryGoldSeal = { id = 9543, qty = 6, name = 'Demons Medal', chancePercent = 100 }, -- guaranteed
}

return catalog
