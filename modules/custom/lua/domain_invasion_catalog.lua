-----------------------------------
-- domain_invasion_catalog.lua
-- Config for the Domain Invasion system (see domain_invasion.lua).
--
-- Every 3 hours, Dahaks or Lamiae assault an Escha zone. Zones alternate
-- between Escha - Zi'Tah (Dahaks + Azi Dahaka) and Escha - Ru'Aun
-- (Lamiae + Naga Raja). FIVE-wave event: four escalating trash waves that
-- culminate in a boss wave with adds. A muster delay lets defenders !diwarp
-- in before wave 1 spawns. Rewards: Escha Silt, Escha Beads, Domain Points
-- (daily cap 80 per player).
--
-- 2026-07-09 RETUNE (report: Spyro -- "2 waves, die super fast, over in <2min,
-- can be over before you warp in"): 2 waves -> 5 escalating waves; per-mob HP
-- and level ramp each wave so a wave isn't melted in seconds (silent difficulty
-- -- baked into the stat blocks, no visible multiplier); time limit 10 -> 15 min;
-- musterDelaySec added so latecomers can rally before the first wave.
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
catalog.musterDelaySec    = 45   -- warm-up after launch before wave 1 (lets people !diwarp in)
catalog.interWaveDelaySec = 12   -- breather + join window between waves
catalog.timeLimitSec      = 900  -- 15 min of fighting (excludes the muster warm-up)

-- ============================================================
-- ZONE CONFIGS
-- ============================================================
-- Each entry defines one battlefield. The two zones alternate on each
-- 3-hour window (zoneIdx in catalog.windows below).
catalog.zones =
{
    -- [1] Escha - Zi'Tah: Dahak flood + Azi Dahaka boss.
    -- 5 waves: level 122 -> 140 and hpMult 3.0 -> 6.5 ramp across the trash
    -- waves so each wave takes real time, then the Azi Dahaka boss wave.
    {
        zone   = 'Escha_ZiTah',
        zoneId = 288,
        label  = "Escha - Zi'Tah",

        waves =
        {
            {
                label = 'Dahak Vanguard', level = 122, base = 5, perDefender = 2,
                groups = { 11480 },
                names  = { 'Escha Dahak', 'Dahak Raider', 'Dahak Vanguard' },
                mods   = { [xi.mod.ATT] = 1600, [xi.mod.ACC] = 720, [xi.mod.HASTE_GEAR] = 80 },
                hpMult = 3.0,
            },
            {
                label = 'Dahak Marauders', level = 126, base = 6, perDefender = 2,
                groups = { 11480 },
                names  = { 'Dahak Marauder', 'Dahak Raider', 'Dahak Skirmisher' },
                mods   = { [xi.mod.ATT] = 1900, [xi.mod.ACC] = 780, [xi.mod.HASTE_GEAR] = 100 },
                hpMult = 4.0,
            },
            {
                label = 'Dahak Ravagers', level = 130, base = 6, perDefender = 2,
                groups = { 11480 },
                names  = { 'Dahak Ravager', 'Dahak Sentinel' },
                mods   = { [xi.mod.ATT] = 2200, [xi.mod.ACC] = 840, [xi.mod.HASTE_GEAR] = 120 },
                hpMult = 5.0,
            },
            {
                label = 'Dahak Dreadguard', level = 135, base = 7, perDefender = 2,
                groups = { 11480 },
                names  = { 'Dahak Dreadguard', 'Dahak Sentinel', 'Dahak Ravager' },
                mods   = { [xi.mod.ATT] = 2500, [xi.mod.ACC] = 900, [xi.mod.HASTE_GEAR] = 140 },
                hpMult = 6.5,
            },
            {
                label = 'Azi Dahaka', level = 140, base = 3, perDefender = 1,
                groups = { 11480 },
                names  = { 'Dahak Dreadguard', 'Dahak Sentinel' },
                mods   = { [xi.mod.ATT] = 2800, [xi.mod.ACC] = 960, [xi.mod.HASTE_GEAR] = 160 },
                hpMult = 6.0,
                boss =
                {
                    name      = 'Azi Dahaka',
                    level     = 150,
                    group     = 11481,
                    mods      = { [xi.mod.ATT] = 3400, [xi.mod.ACC] = 1050, [xi.mod.HASTE_GEAR] = 180 },
                    hpMult    = 8.0,
                    modelSize = 3,
                },
            },
        },
    },

    -- [2] Escha - Ru'Aun: Lamia flood + Naga Raja boss. Symmetric 5-wave ramp.
    {
        zone   = 'Escha_RuAun',
        zoneId = 289,
        label  = "Escha - Ru'Aun",

        waves =
        {
            {
                label = 'Lamia Vanguard', level = 122, base = 5, perDefender = 2,
                groups = { 11482 },
                names  = { 'Escha Lamia', 'Lamia Skirmisher', 'Lamia Archer' },
                mods   = { [xi.mod.ATT] = 1600, [xi.mod.ACC] = 720, [xi.mod.HASTE_GEAR] = 80 },
                hpMult = 3.0,
            },
            {
                label = 'Lamia Raiders', level = 126, base = 6, perDefender = 2,
                groups = { 11482 },
                names  = { 'Lamia Dancer', 'Lamia Archer', 'Lamia Skirmisher' },
                mods   = { [xi.mod.ATT] = 1900, [xi.mod.ACC] = 780, [xi.mod.HASTE_GEAR] = 100 },
                hpMult = 4.0,
            },
            {
                label = 'Lamia Bloodletters', level = 130, base = 6, perDefender = 2,
                groups = { 11482 },
                names  = { 'Lamia Bloodletter', 'Lamia Sentry' },
                mods   = { [xi.mod.ATT] = 2200, [xi.mod.ACC] = 840, [xi.mod.HASTE_GEAR] = 120 },
                hpMult = 5.0,
            },
            {
                label = 'Lamia Champions', level = 135, base = 7, perDefender = 2,
                groups = { 11482 },
                names  = { 'Lamia Champion', 'Lamia Sentry', 'Lamia Bloodletter' },
                mods   = { [xi.mod.ATT] = 2500, [xi.mod.ACC] = 900, [xi.mod.HASTE_GEAR] = 140 },
                hpMult = 6.5,
            },
            {
                label = 'Naga Raja', level = 140, base = 3, perDefender = 1,
                groups = { 11482 },
                names  = { 'Lamia Champion', 'Lamia Sentry' },
                mods   = { [xi.mod.ATT] = 2800, [xi.mod.ACC] = 960, [xi.mod.HASTE_GEAR] = 160 },
                hpMult = 6.0,
                boss =
                {
                    name      = 'Naga Raja',
                    level     = 150,
                    group     = 11483,
                    mods      = { [xi.mod.ATT] = 3400, [xi.mod.ACC] = 1050, [xi.mod.HASTE_GEAR] = 180 },
                    hpMult    = 8.0,
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
    perWaveSilt   = 75,   -- silt per wave clear (×5 = 375 across a full 5-wave run)

    victorySilt   = 200,
    victoryBeads  = 4,
    victoryPoints = 40,   -- Domain Points on victory (cap: 80/day -> 2 clears/day caps)

    timeoutSilt   = 50,
    timeoutBeads  = 1,
    timeoutPoints = 10,   -- Domain Points on time-out consolation

    dailyPointCap = 80,   -- total Domain Points earnable per UTC day
}

return catalog
