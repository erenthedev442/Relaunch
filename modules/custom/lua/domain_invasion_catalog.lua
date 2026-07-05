-----------------------------------
-- domain_invasion_catalog.lua
-- Config for the Domain Invasion system (see domain_invasion.lua).
--
-- Every 3 hours, Dahaks or Lamiae assault an Escha zone. Zones alternate
-- between Escha - Zi'Tah (Dahaks + Azi Dahaka) and Escha - Ru'Aun
-- (Lamiae + Naga Raja). Two-wave event: a trash wave followed by a boss
-- wave with adds. Rewards: Escha Silt, Escha Beads, Domain Points
-- (daily cap 80 per player).
-----------------------------------
local catalog = {}

-- All mob group DB rows live in zone 210 (GM_Home); the engine resolves
-- models from there but the mobs spawn in the actual Escha zone.
catalog.groupZoneId = 210

catalog.spawnRingMin      = 8.0
catalog.spawnRingMax      = 12.0
catalog.warnMinutes       = 5
catalog.graceMinutes      = 10
catalog.tickSeconds       = 30
catalog.interWaveDelaySec = 10
catalog.timeLimitSec      = 600  -- 10 min per assault

-- ============================================================
-- ZONE CONFIGS
-- ============================================================
-- Each entry defines one battlefield. The two zones alternate on each
-- 3-hour window (zoneIdx in catalog.windows below).
catalog.zones =
{
    -- [1] Escha - Zi'Tah: Dahak flood + Azi Dahaka boss
    {
        zone   = 'Escha_ZiTah',
        zoneId = 288,
        label  = "Escha - Zi'Tah",

        waves =
        {
            {
                label = 'Dahak Vanguard', level = 120, base = 5, perDefender = 2,
                groups = { 11480 },
                names  = { 'Escha Dahak', 'Dahak Marauder', 'Dahak Raider', 'Dahak Vanguard' },
                mods   = { [xi.mod.ATT] = 1600, [xi.mod.ACC] = 700, [xi.mod.HASTE_GEAR] = 80 },
                hpMult = 2.0,
            },
            {
                label = 'Azi Dahaka', level = 140, base = 2, perDefender = 1,
                groups = { 11480 },
                names  = { 'Dahak Sentinel', 'Dahak Ravager', 'Dahak Dreadguard' },
                mods   = { [xi.mod.ATT] = 2200, [xi.mod.ACC] = 860, [xi.mod.HASTE_GEAR] = 120 },
                hpMult = 2.5,
                boss =
                {
                    name      = 'Azi Dahaka',
                    level     = 150,
                    group     = 11481,
                    mods      = { [xi.mod.ATT] = 3000, [xi.mod.ACC] = 1000, [xi.mod.HASTE_GEAR] = 160 },
                    hpMult    = 6.0,
                    modelSize = 3,
                },
            },
        },
    },

    -- [2] Escha - Ru'Aun: Lamia flood + Naga Raja boss
    {
        zone   = 'Escha_RuAun',
        zoneId = 289,
        label  = "Escha - Ru'Aun",

        waves =
        {
            {
                label = 'Lamia Vanguard', level = 120, base = 5, perDefender = 2,
                groups = { 11482 },
                names  = { 'Escha Lamia', 'Lamia Archer', 'Lamia Dancer', 'Lamia Skirmisher' },
                mods   = { [xi.mod.ATT] = 1600, [xi.mod.ACC] = 700, [xi.mod.HASTE_GEAR] = 80 },
                hpMult = 2.0,
            },
            {
                label = 'Naga Raja', level = 140, base = 2, perDefender = 1,
                groups = { 11482 },
                names  = { 'Lamia Sentry', 'Lamia Bloodletter', 'Lamia Champion' },
                mods   = { [xi.mod.ATT] = 2200, [xi.mod.ACC] = 860, [xi.mod.HASTE_GEAR] = 120 },
                hpMult = 2.5,
                boss =
                {
                    name      = 'Naga Raja',
                    level     = 150,
                    group     = 11483,
                    mods      = { [xi.mod.ATT] = 3000, [xi.mod.ACC] = 1000, [xi.mod.HASTE_GEAR] = 160 },
                    hpMult    = 6.0,
                    modelSize = 2,
                },
            },
        },
    },
}

-- ============================================================
-- SCHEDULE (UTC)
-- ============================================================
-- Every 3 hours, alternating zones. zoneIdx indexes into catalog.zones.
catalog.windows =
{
    { hour =  0, min = 0, zoneIdx = 1 },
    { hour =  3, min = 0, zoneIdx = 2 },
    { hour =  6, min = 0, zoneIdx = 1 },
    { hour =  9, min = 0, zoneIdx = 2 },
    { hour = 12, min = 0, zoneIdx = 1 },
    { hour = 15, min = 0, zoneIdx = 2 },
    { hour = 18, min = 0, zoneIdx = 1 },
    { hour = 21, min = 0, zoneIdx = 2 },
}

-- ============================================================
-- REWARDS
-- ============================================================
-- perWaveSilt: all players in zone get this on each wave clear.
-- victory*/timeout*: only participants (present at a wave start) get these.
-- Domain Points are hard-capped at dailyPointCap per UTC day per player.
catalog.reward =
{
    perWaveSilt   = 75,   -- silt per wave clear (×2 = 150 on a full 2-wave run)

    victorySilt   = 150,
    victoryBeads  = 3,
    victoryPoints = 30,   -- Domain Points on victory (cap: 80/day)

    timeoutSilt   = 50,
    timeoutBeads  = 1,
    timeoutPoints = 10,   -- Domain Points on time-out consolation

    dailyPointCap = 80,   -- total Domain Points earnable per UTC day
}

return catalog
