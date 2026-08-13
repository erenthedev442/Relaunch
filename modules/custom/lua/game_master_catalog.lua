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
--   mobsPerWave      - always 1; difficulty comes from stats and endurance,
--                      never simultaneous boss pile-ons
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
    -- Wave Master follows the same level model as the rest of Relaunch:
    -- no enemy exceeds level 150. Difficulty comes from HP, offensive
    -- mods, mechanics, and consecutive unique encounters. Every wave
    -- contains exactly one enemy so solo players and trusts are never
    -- subjected to an unavoidable multi-boss alpha strike.
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
        spawnStagger    = 0,
        graceDelay      = 5,
        waveDelay       = 20,
        minLevel        = 115,
        maxLevel        = 115,
        completionBonus = 25,
        markBonus       = 10,
        hpBoost         = 2.5,
        mechanics =
        {
            name   = 'Arena Challenger',
            enrage = { sec = 480, att = 500, haste = 30, msg = 'grows impatient and presses the attack!' },
        },
        mods =
        {
            [xi.mod.ATT]           = 2200,
            [xi.mod.ACC]           = 400,
            [xi.mod.STR]           = 50,
            [xi.mod.DEX]           = 50,
            [xi.mod.HASTE_GEAR]    = 60,
            [xi.mod.DOUBLE_ATTACK] = 6,
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
        spawnStagger    = 0,
        graceDelay      = 5,
        waveDelay       = 10,
        minLevel        = 135,
        maxLevel        = 135,
        completionBonus = 40,
        markBonus       = 12,
        hpBoost         = 4.0,
        mechanics =
        {
            name   = 'Arena Veteran',
            enrage = { sec = 420, att = 750, haste = 40, msg = 'feeds on the battle and quickens!' },
        },
        mods =
        {
            [xi.mod.ATT]           = 2700,
            [xi.mod.ACC]           = 500,
            [xi.mod.STR]           = 75,
            [xi.mod.DEX]           = 75,
            [xi.mod.HASTE_GEAR]    = 100,
            [xi.mod.DOUBLE_ATTACK] = 8,
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
        wavesTotal      = 7,
        mobsPerWave     = 1,
        spawnStagger    = 0,
        graceDelay      = 5,
        waveDelay       = 8,
        minLevel        = 150,
        maxLevel        = 150,
        completionBonus = 80,
        markBonus       = 15,
        hpBoost         = 5.0,
        mechanics =
        {
            name   = 'Arena HNM',
            aoe    = { periodSec = 30, dmgPct = 4, msg = 'unleashes a crushing shockwave!' },
            enrage = { sec = 360, att = 1000, haste = 50, msg = 'enters a killing frenzy!' },
        },
        mods =
        {
            [xi.mod.ATT]           = 3800,
            [xi.mod.ACC]           = 800,
            [xi.mod.STR]           = 125,
            [xi.mod.DEX]           = 125,
            [xi.mod.HASTE_GEAR]    = 150,
            [xi.mod.DOUBLE_ATTACK] = 10,
            [xi.mod.TRIPLE_ATTACK] = 3,
        },
        mobs =
        {
            -- Hard: HNM apex beasts. Cerberus / Hydra / Khimaira are the
            -- iconic Wyrmwall-era HNMs; the full pool is used before it cycles.
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
        -- Augment-T4 challenge: eight single-enemy waves drawn from the
        -- Heavenly Kings. Tuned for T3 augments rather than relic damage.
        wavesTotal      = 8,
        mobsPerWave     = 1,
        spawnStagger    = 0,
        graceDelay      = 10,
        waveDelay       = 10,
        minLevel        = 150,
        maxLevel        = 150,
        completionBonus = 400,
        markBonus       = 20,
        hpBoost         = 12.0,
        mechanics =
        {
            name   = 'Heavenly King',
            aoe    = { periodSec = 25, dmgPct = 3, msg = 'shakes the arena with divine force!' },
            enrage = { sec = 330, att = 1250, haste = 60, msg = 'casts restraint aside!' },
            phases = {
                { hp = 35, action = 'fury', att = 750, haste = 35, msg = 'calls on its final reserve of power!' },
            },
        },
        mods =
        {
            [xi.mod.ATT]           = 4500,
            [xi.mod.ACC]           = 1200,
            [xi.mod.STR]           = 250,
            [xi.mod.DEX]           = 250,
            [xi.mod.HASTE_GEAR]    = 180,
            [xi.mod.DOUBLE_ATTACK] = 12,
        },
        mobs =
        {
            -- Insane: THE FOUR GODS (Byakko/Suzaku/Genbu/Seiryu) -- the complete
            -- set of Heavenly Kings, distinct from every other tier's roster.
            { groupId = 11414, name = 'Byakko' },
            { groupId = 11415, name = 'Suzaku' },
            { groupId = 11429, name = 'Genbu' },
            { groupId = 11430, name = 'Seiryu' },
        },
    },

    Nightmare =
    {
        -- Relic-path capstone: ten elder-wyrm encounters, one per wave. This is a
        -- pre-relic trial, so its stats assume T3/T4 progression gear.
        wavesTotal      = 10,
        mobsPerWave     = 1,
        graceDelay      = 10,
        waveDelay       = 10,
        spawnStagger    = 0,
        minLevel        = 150,
        maxLevel        = 150,
        completionBonus = 800,
        markBonus       = 20,
        hpBoost         = 16.0,
        mechanics =
        {
            name   = 'Elder Wyrm',
            aoe    = { periodSec = 25, dmgPct = 4, msg = 'sweeps the field with elder wrath!' },
            cc     = { periodSec = 45, effect = xi.effect.PARALYSIS, power = 10, dur = 4, msg = 'binds the challengers in draconic dread!' },
            enrage = { sec = 300, att = 1500, haste = 70, msg = 'erupts in ancient fury!' },
        },
        mods =
        {
            [xi.mod.ATT]           = 5200,
            [xi.mod.ACC]           = 1400,
            [xi.mod.STR]           = 350,
            [xi.mod.DEX]           = 350,
            [xi.mod.HASTE_GEAR]    = 200,
            [xi.mod.DOUBLE_ATTACK] = 14,
            [xi.mod.TRIPLE_ATTACK] = 5,
        },
        mobs =
        {
            -- Nightmare: ELDER WYRMS -- the great dragons of Vana'diel.
            { groupId = 11412, name = 'Bahamut' },
            { groupId = 11413, name = 'Ouryu' },
            { groupId = 11431, name = 'Fafnir' },
            { groupId = 11432, name = 'Jormungand' },
        },
    },

    Apocalypse =
    {
        -- Empyrean/Mythic-path capstone: twelve primeval-titan encounters,
        -- one per wave. Stats and mechanics provide the step up, not level.
        wavesTotal      = 12,
        mobsPerWave     = 1,
        graceDelay      = 10,
        waveDelay       = 10,
        spawnStagger    = 0,
        minLevel        = 150,
        maxLevel        = 150,
        completionBonus = 1200,
        markBonus       = 20,
        hpBoost         = 20.0,
        mechanics =
        {
            name   = 'Primeval Titan',
            aoe    = { periodSec = 22, dmgPct = 5, msg = 'splits the arena with primeval force!' },
            enrage = { sec = 280, att = 2000, haste = 80, msg = 'becomes an unstoppable catastrophe!' },
            phases = {
                { hp = 40, action = 'nuke', dmgPct = 4, msg = 'detonates the ancient power within!' },
            },
        },
        mods =
        {
            [xi.mod.ATT]           = 6500,
            [xi.mod.ACC]           = 1700,
            [xi.mod.STR]           = 450,
            [xi.mod.DEX]           = 450,
            [xi.mod.HASTE_GEAR]    = 225,
            [xi.mod.DOUBLE_ATTACK] = 18,
            [xi.mod.TRIPLE_ATTACK] = 7,
        },
        mobs =
        {
            -- Apocalypse: PRIMEVAL TITANS -- the original three HNMs + Sandworm.
            { groupId = 11433, name = 'Adamantoise' },
            { groupId = 11434, name = 'Aspidochelone' },
            { groupId = 11435, name = 'Behemoth' },
            { groupId = 11436, name = 'Sandworm' },
        },
    },

    Oblivion =
    {
        -- Aeonic-path capstone: fourteen void-sovereign encounters, one
        -- per wave, cycling the full roster before any model repeats.
        wavesTotal      = 14,
        mobsPerWave     = 1,
        graceDelay      = 10,
        waveDelay       = 10,
        spawnStagger    = 0,
        minLevel        = 150,
        maxLevel        = 150,
        completionBonus = 2000,
        markBonus       = 20,
        hpBoost         = 24.0,
        mechanics =
        {
            name   = 'Void Sovereign',
            aoe    = { periodSec = 20, dmgPct = 5, msg = 'tears open a wave of void energy!' },
            drain  = { periodSec = 30, healPct = 1 },
            enrage = { sec = 260, att = 2500, haste = 90, msg = 'unseals its sovereign power!' },
        },
        mods =
        {
            [xi.mod.ATT]           = 8000,
            [xi.mod.ACC]           = 2000,
            [xi.mod.STR]           = 600,
            [xi.mod.DEX]           = 600,
            [xi.mod.HASTE_GEAR]    = 240,
            [xi.mod.DOUBLE_ATTACK] = 22,
            [xi.mod.TRIPLE_ATTACK] = 10,
            [xi.mod.QUAD_ATTACK]   = 2,
        },
        mobs =
        {
            -- Oblivion: VOID SOVEREIGNS -- the endgame gods, now their own tier.
            { groupId = 11425, name = 'Kirin' },
            { groupId = 11426, name = 'Absolute Virtue' },
            { groupId = 11428, name = 'Pandemonium Warden' },
            { groupId = 11427, name = 'Shinryu' },
            { groupId = 11441, name = 'Jailer of Love' },
        },
    },

    Ragnarok =
    {
        -- Prime-path capstone: sixteen encounters with The Unmade, one
        -- per wave, cycling the full roster before any model repeats.
        wavesTotal      = 16,
        mobsPerWave     = 1,
        graceDelay      = 10,
        waveDelay       = 10,
        spawnStagger    = 0,
        minLevel        = 150,
        maxLevel        = 150,
        completionBonus = 2800,
        markBonus       = 20,
        hpBoost         = 30.0,
        mechanics =
        {
            name   = 'The Unmade',
            aoe    = { periodSec = 18, dmgPct = 6, msg = 'unmakes the ground beneath the challengers!' },
            cc     = { periodSec = 35, effect = xi.effect.TERROR, power = 1, dur = 3, msg = 'reveals the end of all things!' },
            enrage = { sec = 240, att = 3000, haste = 100, msg = 'begins the final unmaking!' },
            phases = {
                { hp = 30, action = 'fury', att = 1500, haste = 60, msg = 'refuses its own destruction!' },
            },
        },
        mods =
        {
            [xi.mod.ATT]           = 10000,
            [xi.mod.ACC]           = 2300,
            [xi.mod.STR]           = 750,
            [xi.mod.DEX]           = 750,
            [xi.mod.HASTE_GEAR]    = 256,
            [xi.mod.DOUBLE_ATTACK] = 25,
            [xi.mod.TRIPLE_ATTACK] = 12,
            [xi.mod.QUAD_ATTACK]   = 4,
        },
        mobs =
        {
            -- Ragnarok: THE UNMADE -- ultimate weapons + death gods.
            { groupId = 11437, name = 'Ultima' },
            { groupId = 11438, name = 'Omega' },
            { groupId = 11439, name = 'Odin' },
            { groupId = 11440, name = 'Dynamis Lord' },
            { groupId = 11442, name = 'Provenance Watcher' },
        },
    },

    Terror =
    {
        -- Ultimate optional challenge: eighteen Abyssal Terror encounters,
        -- one per wave. It exceeds Ragnarok in endurance, stats, mechanics,
        -- and rewards while preserving the one-enemy-at-a-time rule.
        wavesTotal      = 18,
        mobsPerWave     = 1,
        graceDelay      = 10,
        waveDelay       = 8,
        spawnStagger    = 0,
        minLevel        = 150,
        maxLevel        = 150,
        completionBonus = 4000,
        markBonus       = 30,
        hpBoost         = 36.0,
        mechanics =
        {
            name   = 'Abyssal Terror',
            aoe    = { periodSec = 16, dmgPct = 7, msg = 'floods the arena with abyssal power!' },
            cc     = { periodSec = 30, effect = xi.effect.TERROR, power = 1, dur = 4, msg = 'freezes the challengers in primal fear!' },
            drain  = { periodSec = 25, healPct = 1 },
            enrage = { sec = 220, att = 3500, haste = 110, msg = 'erupts with forbidden strength!' },
            phases = {
                { hp = 30, action = 'fury', att = 1800, haste = 70, msg = 'tears open the abyss itself!' },
            },
        },
        mods =
        {
            [xi.mod.ATT]           = 12000,
            [xi.mod.ACC]           = 2600,
            [xi.mod.STR]           = 900,
            [xi.mod.DEX]           = 900,
            [xi.mod.HASTE_GEAR]    = 256,
            [xi.mod.DOUBLE_ATTACK] = 28,
            [xi.mod.TRIPLE_ATTACK] = 15,
            [xi.mod.QUAD_ATTACK]   = 5,
        },
        mobs =
        {
            -- Terror: ABYSSAL TERRORS -- six distinct Abyssea apex beasts.
            { groupId = 11443, name = 'Glavoid' },
            { groupId = 11444, name = 'Chloris' },
            { groupId = 11445, name = 'Sarameya' },
            { groupId = 11446, name = 'Orthrus' },
            { groupId = 11447, name = 'Bukhis' },
            { groupId = 11448, name = 'Sobek' },
        },
    },
}

-- Order the difficulties appear in the menu (Lua tables aren't ordered).
-- NOTE: order also assigns the GM_Wave_Clears full-clear BIT (index-1): Easy=1,
-- Normal=2, Hard=4, Insane=8, Nightmare=16, Apocalypse=32, Oblivion=64,
-- Ragnarok=128, Terror=256. Augment and weapon gates consume these through
-- game_master_progress.lua. Only ever APPEND here -- reordering would rewrite
-- everyone's earned bits. (Nine tiers exceed the flat eight-option menu, so
-- showStartMenu paginates -- see GameMaster.lua.)
catalog.difficultyOrder = { 'Easy', 'Normal', 'Hard', 'Insane', 'Nightmare', 'Apocalypse', 'Oblivion', 'Ragnarok', 'Terror' }

-- Spawn ring radius around the player. Mobs appear at this distance and
-- random angles so they don't all stack on top of each other.
catalog.spawnRing =
{
    minRadius = 5.0,
    maxRadius = 8.0,
}

-- Compatibility fallback for the spawn engine. Live tiers use one mob per wave,
-- so no intra-wave stagger is needed.
catalog.spawnStagger = 0

return catalog
