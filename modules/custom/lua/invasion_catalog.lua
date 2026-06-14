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

-- Battleground: Al Zahbi.
catalog.zone   = 'Al_Zahbi'
catalog.zoneId = 48

-- Mob groups are still registered under zone 210 (GM_Home) in the DB.
-- groupZoneId tells the engine where to look up the group definitions.
catalog.groupZoneId = 210

-- Fixed spawn anchor: mobs always pour in from this spot (center of the
-- Al Zahbi market plaza) regardless of where defenders are standing.
-- Tune with !pos while standing at the desired spawn center, then update.
catalog.fixedSpawn = { x = -35, y = -1, z = -31 }

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
        label = 'Vanguard', level = 110, base = 5, perDefender = 2,
        groups = { 11355, 11356, 11357, 11358 },
        names  = { 'Voidsent Raider', 'Voidsent Skirmisher', 'Voidsent Scout', 'Voidsent Stalker' },
        mods = { [xi.mod.ATT] = 1400, [xi.mod.ACC] = 640, [xi.mod.HASTE_GEAR] = 75 },
        hpMult = 1.8,
    },
    {
        label = 'Shock Troops', level = 125, base = 5, perDefender = 2,
        groups = { 11359, 11360, 11361 },
        names  = { 'Voidsent Marauder', 'Voidsent Impaler', 'Voidsent Crusher', 'Voidsent Berserker' },
        mods = { [xi.mod.ATT] = 1900, [xi.mod.ACC] = 740, [xi.mod.HASTE_GEAR] = 100, [xi.mod.DOUBLE_ATTACK] = 6 },
        hpMult = 2.2,
    },
    {
        label = 'Dreadguard', level = 140, base = 5, perDefender = 2,
        groups = { 11362, 11363, 11365 },
        names  = { 'Voidsent Ravager', 'Voidsent Dreadknight', 'Voidsent Juggernaut', 'Voidsent Warden' },
        mods = { [xi.mod.ATT] = 2400, [xi.mod.ACC] = 860, [xi.mod.HASTE_GEAR] = 140, [xi.mod.DOUBLE_ATTACK] = 9 },
        hpMult = 2.6,
    },
    {
        label = 'Apex Guard', level = 155, base = 4, perDefender = 2,
        groups = { 11364, 11366, 11367 },
        names  = { 'Voidsent Houndmaster', 'Voidsent Banneret', 'Voidsent Destroyer', 'Voidsent Champion' },
        mods = { [xi.mod.ATT] = 2900, [xi.mod.ACC] = 980, [xi.mod.HASTE_GEAR] = 170, [xi.mod.DOUBLE_ATTACK] = 11 },
        hpMult = 3.0,
    },
    {
        label = 'The Warlord', level = 165, base = 3, perDefender = 1,
        groups = { 11368, 11369 },
        names  = { 'Voidsent Sentinel', 'Voidsent Harbinger', 'Voidsent Executioner' },
        mods = { [xi.mod.ATT] = 3200, [xi.mod.ACC] = 1040, [xi.mod.HASTE_GEAR] = 185, [xi.mod.DOUBLE_ATTACK] = 12 },
        hpMult = 3.5,
        boss = {
            name = 'Voidsent Warlord', level = 175, group = 11368,
            mods = { [xi.mod.ATT] = 3800, [xi.mod.ACC] = 1120, [xi.mod.HASTE_GEAR] = 210, [xi.mod.DOUBLE_ATTACK] = 14 },
            hpMult = 8.0,
            modelSize = 3,
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
