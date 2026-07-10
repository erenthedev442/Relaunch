-----------------------------------
-- game_master_catalog.lua
-- Data for the Game Master NPC (modules/custom/lua/GameMaster.lua).
--
-- Defines difficulty presets and which mob groupIds each difficulty
-- can pull from. The groupIds 11400-11431 live in
-- modules/custom/sql/gm_master_extra_mobs.sql (zone 289 / Escha - Ru'Aun)
-- and are deliberately distinct from the Hunting League pool so wave
-- fights have visual variety -- Easy uses classic camp NMs, Normal
-- uses mid-tier classics, Hard uses HNM apex beasts, Insane uses
-- gods and wyrms.
--
-- To add/remove mobs from a difficulty: edit the `mobs` array. The
-- groupId must exist in mob_groups.sql for the configured huntZoneId.
-- To change the NPC's position or which zone it lives in: edit npcPos.
-- =========================================================

local catalog = {}

-- Escha_RuAun (zone 289): a huge, open Escha hub -- far more room than the
-- narrow Hall of the Gods (251), so multi-mob waves spawn in the open instead
-- of clipping into the walls. Trusts are already enabled here (zone misc 2048).
--
-- Primary reference point (zone + zoneId are what the module actually reads for
-- the require, the onInitialize override, and the mobs' groupZoneId; x/y/z are a
-- fallback only used if npcPositions is empty). Kept in sync with npcPositions[1]
-- and with the !wavemaster warp target.
catalog.npcPos =
{
    zone     = 'Escha_RuAun',
    zoneId   = 289,
    x        =  258.6571,
    y        = -70.0200,
    z        =  509.2923,
    rotation = 149,
}

-- Four Game Masters spread across Escha - Ru'Aun (zone 289), one per owner-chosen
-- !pos spot (2026-07-09). Each is a FULL, independent Game Master: talk to any one
-- and its waves spawn around you right there (spawnRing is anchored on the player),
-- so every location hosts its own self-contained fight. All sit on floor y=-70.02.
-- Nudge any spot with !pos in-game; add/remove entries freely.
catalog.npcPositions =
{
    { x =  258.6571, y = -70.0200, z =  509.2923, rot = 149 },
    { x = -403.9470, y = -70.0200, z =  400.5327, rot = 246 },
    { x = -505.4169, y = -70.0200, z = -264.5769, rot =  74 },
    { x =  553.0083, y = -70.0200, z =  -86.2772, rot = 249 },
}

-- Difficulty presets. Each preset is a self-contained spec:
--   wavesTotal       - how many waves the session runs
--   mobsPerWave      - mobs spawned per wave (random picks from `mobs`)
--   graceDelay       - seconds after "Start!" before wave 1 spawns
--   waveDelay        - seconds after a wave is cleared before next spawns
--   minLevel/maxLevel - mob level range. REQUIRED - without these,
--                      `insertDynamicEntity` defaults the spawn to level
--                      255 and the engine logs an error per spawn. HL uses
--                      Lv150 uniformly; we tier here so Easy is gentler
--                      and Insane bites harder than the standard HL bar.
--   mobs             - pool of { groupId, name } to draw spawns from
--   completionBonus  - HL_Points awarded on full clear
--   markBonus        - bonus added per kill (small, not the full HL amount)
catalog.difficulties =
{
    -- Stat-mod scaling rebalance (2026-05): HP gets a SLIGHT bump per
    -- tier (waves shouldn't last forever - pile-on tempo is the point),
    -- but the offensive package gets a SIGNIFICANT one. ACC bumps to
    -- guarantee the mob lands swings on geared L99 players, ATT bumps
    -- to make those landed hits hurt, and HASTE / DOUBLE_ATTACK /
    -- TRIPLE_ATTACK to stack additional pressure per second.
    --
    -- Engine notes:
    --   xi.mod.HASTE_GEAR is 1024ths of 1% (engine caps total gear
    --   haste around 25% = ~256). Values past 256 are symbolic.
    --   DOUBLE_ATTACK / TRIPLE_ATTACK are % chance per swing.
    --   DEX feeds the ACC formula (~0.75 DEX = +1 ACC), STR feeds ATT,
    --   so bumping both compounds with the explicit ACC/ATT mods.
    Easy =
    {
        wavesTotal      = 3,
        mobsPerWave     = 1,
        graceDelay      = 5,
        waveDelay       = 20,
        minLevel        = 125,
        maxLevel        = 125,
        completionBonus = 50,
        markBonus       = 20,
        hpBoost         = 4.0,   -- bumped from 1.5 (2026-05-30) -- Easy fights were ending in seconds.
        mods =
        {
            [xi.mod.ATT]           = 2000,
            [xi.mod.ACC]           = 700,
            [xi.mod.STR]           = 100,
            [xi.mod.DEX]           = 100,
            [xi.mod.HASTE_GEAR]    = 100,   -- ~10%
            [xi.mod.DOUBLE_ATTACK] = 10,
        },
        mobs =
        {
            -- Easy: classic camp NMs. Different creature types per slot
            -- (lizard / rabbit / antlion / dhalmel) so a 3-wave Easy run
            -- never repeats a silhouette.
            { groupId = 11400, name = 'Argus' },
            { groupId = 11401, name = 'Stray Mary' },
            { groupId = 11402, name = 'Dune Widow' },
            { groupId = 11403, name = 'Capricornus' },
            { groupId = 11416, name = 'Leaping Lizzy' },
            { groupId = 11417, name = 'Tom Tit Tat' },
            { groupId = 11418, name = 'Aquarius' },
        },
    },

    Normal =
    {
        wavesTotal      = 5,
        mobsPerWave     = 1,
        graceDelay      = 5,
        waveDelay       = 25,
        minLevel        = 150,
        maxLevel        = 150,
        completionBonus = 100,
        markBonus       = 20,
        hpBoost         = 6.0,   -- bumped from 2.0 (2026-05-30) -- mid-tier should feel meaningful, not paper.
        mods =
        {
            [xi.mod.ATT]           = 4000,
            [xi.mod.ACC]           = 1100,
            [xi.mod.STR]           = 200,
            [xi.mod.DEX]           = 200,
            [xi.mod.HASTE_GEAR]    = 150,   -- ~15%
            [xi.mod.DOUBLE_ATTACK] = 15,
            [xi.mod.TRIPLE_ATTACK] = 3,
        },
        mobs =
        {
            -- Normal: mid-tier classics with strong visual diversity --
            -- bogy / statue / cluster / elemental. Across 5 waves, you'll
            -- see a mix of demons, eyes, bombs, and floaty spirits.
            { groupId = 11404, name = 'Boggelmann' },
            { groupId = 11405, name = 'Hakutaku' },
            { groupId = 11406, name = 'Steam Cleaner' },
            { groupId = 11407, name = 'Faust' },
            { groupId = 11419, name = 'Serket' },
            { groupId = 11420, name = 'Simurgh' },
            { groupId = 11421, name = 'Roc' },
        },
    },

    Hard =
    {
        wavesTotal      = 5,
        mobsPerWave     = 2,
        graceDelay      = 5,
        waveDelay       = 25,
        minLevel        = 175,
        maxLevel        = 175,
        completionBonus = 200,
        markBonus       = 20,
        hpBoost         = 8.0,   -- bumped from 2.5 (2026-05-30) -- Hard tier deserves a real endurance check.
        mods =
        {
            [xi.mod.ATT]           = 6500,
            [xi.mod.ACC]           = 1500,
            [xi.mod.STR]           = 350,
            [xi.mod.DEX]           = 350,
            [xi.mod.HASTE_GEAR]    = 200,   -- ~20%
            [xi.mod.DOUBLE_ATTACK] = 20,
            [xi.mod.TRIPLE_ATTACK] = 8,
        },
        mobs =
        {
            -- Hard: HNM apex beasts. Cerberus / Hydra / Khimaira are the
            -- iconic Wyrmwall-era HNMs; Tiamat adds a wyrm so 2-mob
            -- pile-ons feel like a legitimate raid scenario.
            { groupId = 11408, name = 'Cerberus' },
            { groupId = 11409, name = 'Hydra' },
            { groupId = 11410, name = 'Khimaira' },
            { groupId = 11411, name = 'Tiamat' },
            { groupId = 11422, name = 'Nidhogg' },
            { groupId = 11423, name = 'King Behemoth' },
            { groupId = 11424, name = 'Vrtra' },
        },
    },

    Insane =
    {
        -- Insane fights endgame gods (Kirin / AV / PW / Shinryu) in
        -- pile-on waves. Previous tuning (3 waves x 1 mob) was actually
        -- LESS work than Hard (5 x 2 = 10 kills) - geared L99 groups
        -- dropped the lone gods faster than the announcement cleared
        -- chat. New tuning is 5 waves of 3 simultaneous gods at level
        -- 200, with a tight 15s waveDelay so there's no breather
        -- between pile-ons. 15 endgame kills total.
        --
        -- Why not bump beyond L200: these gods have fixed HP overrides
        -- in modules/custom/sql/hunting_league_gm_home_mobs.sql
        -- (Kirin 60k, AV 66k, PW 147k, Shinryu pool-default), so level
        -- only affects damage / acc / eva. L200 is the highest stat
        -- profile that's confirmed-hittable on this server; going
        -- higher risks accuracy/evasion outrunning L99 gear. If you
        -- want more pain later, bump min/maxLevel to 215-225 in 5-pt
        -- steps and check whether the group can still land melee.
        wavesTotal      = 5,
        mobsPerWave     = 3,
        graceDelay      = 10,
        waveDelay       = 15,
        minLevel        = 200,
        maxLevel        = 200,
        completionBonus = 400,
        markBonus       = 20,
        hpBoost         = 12.0,  -- bumped from 3.0 (2026-05-30) -- gods should feel like gods, not paper waves.
        mods =
        {
            -- At L200 + 3-mob pile-ons with 15s breathers, the mods
            -- need to outrun a geared L99 group's mitigation. ACC must
            -- punch through ~1200 EVA stacks; ATT must matter against
            -- 2000+ DEF stacks.
            [xi.mod.ATT]           = 10000,
            [xi.mod.ACC]           = 2000,
            [xi.mod.STR]           = 500,
            [xi.mod.DEX]           = 500,
            [xi.mod.HASTE_GEAR]    = 256,   -- gear-haste cap
            [xi.mod.DOUBLE_ATTACK] = 25,
            [xi.mod.TRIPLE_ATTACK] = 12,
        },
        mobs =
        {
            -- Insane: gods + legendary wyrms from outside the Hunting
            -- League's AV/PW/Shinryu pool. Bahamut headlines the dragon
            -- god slot, Ouryu is the wyrm of myth, Byakko and Suzaku
            -- bring the Four Heavenly Kings flavor. A 3-mob pile-on at
            -- this tier shows three distinct god silhouettes per wave.
            { groupId = 11412, name = 'Bahamut' },
            { groupId = 11413, name = 'Ouryu' },
            { groupId = 11414, name = 'Byakko' },
            { groupId = 11415, name = 'Suzaku' },
            { groupId = 11425, name = 'Kirin' },
            { groupId = 11426, name = 'Absolute Virtue' },
            { groupId = 11427, name = 'Shinryu' },
        },
    },

    Nightmare =
    {
        -- Beyond Insane: 7 waves of 4 simultaneous supreme gods at level 225.
        -- Designed for full geared parties with deep Prestige investment.
        -- 28 total kills. waveDelay is 10s -- barely enough to breathe.
        -- spawnStagger=5: 4 gods arrive at t+0/5/10/15s. The global 30s
        -- stagger stacks 90s of dead air while players wait for gods 2-4;
        -- 5s lets all four pile on within 15s for a true chaos wave.
        wavesTotal      = 7,
        mobsPerWave     = 4,
        graceDelay      = 10,
        waveDelay       = 10,
        spawnStagger    = 5,
        minLevel        = 225,
        maxLevel        = 225,
        completionBonus = 800,
        markBonus       = 20,
        hpBoost         = 20.0,
        mods =
        {
            [xi.mod.ATT]           = 15000,
            [xi.mod.ACC]           = 2500,
            [xi.mod.STR]           = 700,
            [xi.mod.DEX]           = 700,
            [xi.mod.HASTE_GEAR]    = 256,
            [xi.mod.DOUBLE_ATTACK] = 30,
            [xi.mod.TRIPLE_ATTACK] = 18,
            [xi.mod.QUAD_ATTACK]   = 5,
        },
        mobs =
        {
            -- Nightmare pulls from the combined pool of ultimate FFXI gods --
            -- Kirin, Absolute Virtue, Pandemonium Warden, Shinryu.
            -- Four different divine models per wave pile-on.
            { groupId = 11425, name = 'Kirin' },
            { groupId = 11426, name = 'Absolute Virtue' },
            { groupId = 11428, name = 'Pandemonium Warden' },
            { groupId = 11427, name = 'Shinryu' },
        },
    },

    Apocalypse =
    {
        -- Beyond Nightmare. The step up is carried by HP (x30) + a heavier
        -- offensive package + one more wave, NOT by level: Nightmare already sits
        -- at L225, past the L200 "confirmed-hittable" mark, so pushing level higher
        -- risks mob EVASION outrunning geared L99 melee (players whiff = un-fun,
        -- not hard). 8 waves x 4 gods = 32 kills, 10s tempo, 5s stagger.
        wavesTotal      = 8,
        mobsPerWave     = 4,
        graceDelay      = 10,
        waveDelay       = 10,
        spawnStagger    = 5,
        minLevel        = 225,
        maxLevel        = 225,
        completionBonus = 1200,
        markBonus       = 20,
        hpBoost         = 30.0,
        mods =
        {
            [xi.mod.ATT]           = 20000,
            [xi.mod.ACC]           = 2800,
            [xi.mod.STR]           = 900,
            [xi.mod.DEX]           = 900,
            [xi.mod.HASTE_GEAR]    = 256,
            [xi.mod.DOUBLE_ATTACK] = 35,
            [xi.mod.TRIPLE_ATTACK] = 22,
            [xi.mod.QUAD_ATTACK]   = 8,
        },
        mobs =
        {
            { groupId = 11425, name = 'Kirin' },
            { groupId = 11426, name = 'Absolute Virtue' },
            { groupId = 11428, name = 'Pandemonium Warden' },
            { groupId = 11427, name = 'Shinryu' },
        },
    },

    Oblivion =
    {
        -- The current ceiling: 10 waves of 5 gods = 50 kills, an 8s waveDelay +
        -- 4s stagger so five gods pile on almost at once. HP x45; the mods sit
        -- just under the int16 mob-mod cap (~31k -- ATT 26000 is the headroom
        -- limit). Level nudged one cautious step to 230 (re-check that melee still
        -- lands before going higher). Only the deepest Prestige-geared full parties
        -- should clear this. Push future pain via HP / mods / counts, not level.
        wavesTotal      = 10,
        mobsPerWave     = 5,
        graceDelay      = 10,
        waveDelay       = 8,
        spawnStagger    = 4,
        minLevel        = 230,
        maxLevel        = 230,
        completionBonus = 2000,
        markBonus       = 20,
        hpBoost         = 45.0,
        mods =
        {
            [xi.mod.ATT]           = 26000,
            [xi.mod.ACC]           = 3200,
            [xi.mod.STR]           = 1200,
            [xi.mod.DEX]           = 1200,
            [xi.mod.HASTE_GEAR]    = 256,
            [xi.mod.DOUBLE_ATTACK] = 40,
            [xi.mod.TRIPLE_ATTACK] = 28,
            [xi.mod.QUAD_ATTACK]   = 12,
        },
        mobs =
        {
            { groupId = 11425, name = 'Kirin' },
            { groupId = 11426, name = 'Absolute Virtue' },
            { groupId = 11428, name = 'Pandemonium Warden' },
            { groupId = 11427, name = 'Shinryu' },
        },
    },
}

-- Order the difficulties appear in the menu (Lua tables aren't ordered).
-- NOTE: order also assigns the GM_Wave_Clears full-clear BIT (index-1): Easy=1,
-- Normal=2, Hard=4, Insane=8, Nightmare=16, Apocalypse=32, Oblivion=64. The
-- Augment Moogle gate masks `& 31`, so tiers past Nightmare don't disturb it.
-- Only ever APPEND here -- reordering would rewrite everyone's earned bits.
catalog.difficultyOrder = { 'Easy', 'Normal', 'Hard', 'Insane', 'Nightmare', 'Apocalypse', 'Oblivion' }

-- Spawn ring radius around the player. Mobs appear at this distance and
-- random angles so they don't all stack on top of each other.
catalog.spawnRing =
{
    minRadius = 5.0,
    maxRadius = 8.0,
}

-- Seconds between each mob spawn within a single wave.
-- 0 = all mobs spawn simultaneously (original behaviour).
-- 30 = first mob spawns immediately, second at t+30s, third at t+60s, etc.
-- Players get a chat notification when each new mob arrives.
catalog.spawnStagger = 30

return catalog
