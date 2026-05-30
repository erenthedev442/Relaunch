-----------------------------------
-- game_master_catalog.lua
-- Data for the Game Master NPC (modules/custom/lua/GameMaster.lua).
--
-- Defines difficulty presets and which mob groupIds each difficulty
-- can pull from. The groupIds 11400-11415 live in
-- modules/custom/sql/gm_master_extra_mobs.sql (zone 210 / GM Home)
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

-- Balga's Dais (zone 146): dedicated wave-fight arena.
-- Coordinates match the zone's default player spawn point so the
-- NPC is right in front of players when they zone or !wavemaster in.
catalog.npcPos =
{
    zone     = 'Balgas_Dais',
    zoneId   = 146,
    x        = 317.842,
    y        = -126.158,
    z        = 383.000,
    rotation = 127,
}

-- Difficulty presets. Each preset is a self-contained spec:
--   wavesTotal       — how many waves the session runs
--   mobsPerWave      — mobs spawned per wave (random picks from `mobs`)
--   graceDelay       — seconds after "Start!" before wave 1 spawns
--   waveDelay        — seconds after a wave is cleared before next spawns
--   minLevel/maxLevel — mob level range. REQUIRED — without these,
--                      `insertDynamicEntity` defaults the spawn to level
--                      255 and the engine logs an error per spawn. HL uses
--                      Lv150 uniformly; we tier here so Easy is gentler
--                      and Insane bites harder than the standard HL bar.
--   mobs             — pool of { groupId, name } to draw spawns from
--   completionBonus  — HL_Points awarded on full clear
--   markBonus        — bonus added per kill (small, not the full HL amount)
catalog.difficulties =
{
    -- Stat-mod scaling rebalance (2026-05): HP gets a SLIGHT bump per
    -- tier (waves shouldn't last forever — pile-on tempo is the point),
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
        completionBonus = 5,
        markBonus       = 5,
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
        completionBonus = 10,
        markBonus       = 15,
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
        completionBonus = 20,
        markBonus       = 30,
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
        },
    },

    Insane =
    {
        -- Insane fights endgame gods (Kirin / AV / PW / Shinryu) in
        -- pile-on waves. Previous tuning (3 waves × 1 mob) was actually
        -- LESS work than Hard (5 × 2 = 10 kills) — geared L99 groups
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
        -- want more pain later, bump min/maxLevel to 215–225 in 5-pt
        -- steps and check whether the group can still land melee.
        wavesTotal      = 5,
        mobsPerWave     = 3,
        graceDelay      = 10,
        waveDelay       = 15,
        minLevel        = 200,
        maxLevel        = 200,
        completionBonus = 40,
        markBonus       = 250,
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
        },
    },
}

-- Order the difficulties appear in the menu (Lua tables aren't ordered).
catalog.difficultyOrder = { 'Easy', 'Normal', 'Hard', 'Insane' }

-- Spawn ring radius around the player. Mobs appear at this distance and
-- random angles so they don't all stack on top of each other.
catalog.spawnRing =
{
    minRadius = 6.0,
    maxRadius = 9.0,
}

return catalog
