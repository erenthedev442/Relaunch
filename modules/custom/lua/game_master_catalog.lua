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
        spawnStagger    = 0,
        graceDelay      = 5,
        waveDelay       = 20,
        minLevel        = 125,
        maxLevel        = 125,
        completionBonus = 50,
        markBonus       = 20,
        hpBoost         = 4.0,   -- bumped from 1.5 (2026-05-30) -- Easy fights were ending in seconds.
        mechanics =
        {
            name   = 'Arena Challenger',
            enrage = { sec = 300, att = 1500, haste = 60, msg = 'grows impatient and presses the attack!' },
        },
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
        spawnStagger    = 0,
        graceDelay      = 5,
        waveDelay       = 10,   -- 25 -> 10 (2026-07-10): faster wave tempo
        minLevel        = 150,
        maxLevel        = 150,
        completionBonus = 100,
        markBonus       = 20,
        hpBoost         = 5.0,
        mechanics =
        {
            name   = 'Arena Veteran',
            drain  = { periodSec = 15, healPct = 1 },
            enrage = { sec = 270, att = 2000, haste = 70, msg = 'feeds on the battle and quickens!' },
        },
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
        spawnStagger    = 3,
        graceDelay      = 5,
        waveDelay       = 10,   -- 25 -> 10 (2026-07-10): faster wave tempo
        minLevel        = 175,
        maxLevel        = 175,
        completionBonus = 200,
        markBonus       = 20,
        hpBoost         = 6.0,
        mechanics =
        {
            name   = 'Arena HNM',
            aoe    = { periodSec = 20, dmgPct = 8, msg = 'unleashes a crushing shockwave!' },
            enrage = { sec = 240, att = 3000, haste = 90, msg = 'enters a killing frenzy!' },
        },
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
        -- Augment-T4 challenge: five waves of three Heavenly Kings. A short
        -- stagger keeps the pile-on readable without the old 30-60s dead air.
        --
        -- Why not bump beyond L200: level affects damage / acc / eva, and L200
        -- is the highest stat
        -- profile that's confirmed-hittable on this server; going
        -- higher risks accuracy/evasion outrunning L99 gear. If you
        -- want more pain later, bump min/maxLevel to 215-225 in 5-pt
        -- steps and check whether the group can still land melee.
        wavesTotal      = 5,
        mobsPerWave     = 3,
        spawnStagger    = 3,
        graceDelay      = 10,
        waveDelay       = 15,
        minLevel        = 200,
        maxLevel        = 200,
        completionBonus = 400,
        markBonus       = 20,
        hpBoost         = 8.0,
        mechanics =
        {
            name   = 'Heavenly King',
            aoe    = { periodSec = 18, dmgPct = 7, msg = 'shakes the arena with divine force!' },
            enrage = { sec = 220, att = 4000, haste = 110, msg = 'casts restraint aside!' },
            phases = {
                { hp = 35, action = 'fury', att = 2000, haste = 70, msg = 'calls on its final reserve of power!' },
            },
        },
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
        -- Relic-path capstone: five waves of four elder wyrms at level 225.
        -- Twenty kills make this a coordinated challenge without the previous
        -- fourfold workload jump from Insane.
        wavesTotal      = 5,
        mobsPerWave     = 4,
        graceDelay      = 10,
        waveDelay       = 10,
        spawnStagger    = 3,
        minLevel        = 225,
        maxLevel        = 225,
        completionBonus = 800,
        markBonus       = 20,
        hpBoost         = 10.0,
        mechanics =
        {
            name   = 'Elder Wyrm',
            aoe    = { periodSec = 17, dmgPct = 6, msg = 'sweeps the field with elder wrath!' },
            cc     = { periodSec = 32, effect = xi.effect.PARALYSIS, power = 20, dur = 6, msg = 'binds the challengers in draconic dread!' },
            enrage = { sec = 210, att = 5000, haste = 120, msg = 'erupts in ancient fury!' },
        },
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
            -- Nightmare: ELDER WYRMS -- the great dragons of Vana'diel.
            { groupId = 11412, name = 'Bahamut' },
            { groupId = 11413, name = 'Ouryu' },
            { groupId = 11431, name = 'Fafnir' },
            { groupId = 11432, name = 'Jormungand' },
        },
    },

    Apocalypse =
    {
        -- Empyrean/Mythic-path capstone. The step up is carried by HP,
        -- mechanics, and one more wave, NOT by level: Nightmare already sits
        -- at L225, past the L200 "confirmed-hittable" mark, so pushing level higher
        -- risks mob EVASION outrunning geared L99 melee (players whiff = un-fun,
        -- not hard). Six waves x four titans = 24 kills.
        wavesTotal      = 6,
        mobsPerWave     = 4,
        graceDelay      = 10,
        waveDelay       = 10,
        spawnStagger    = 3,
        minLevel        = 225,
        maxLevel        = 225,
        completionBonus = 1200,
        markBonus       = 20,
        hpBoost         = 14.0,
        mechanics =
        {
            name   = 'Primeval Titan',
            aoe    = { periodSec = 16, dmgPct = 7, msg = 'splits the arena with primeval force!' },
            enrage = { sec = 200, att = 6000, haste = 130, msg = 'becomes an unstoppable catastrophe!' },
            phases = {
                { hp = 40, action = 'nuke', dmgPct = 7, msg = 'detonates the ancient power within!' },
            },
        },
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
            -- Apocalypse: PRIMEVAL TITANS -- the original three HNMs + Sandworm.
            { groupId = 11433, name = 'Adamantoise' },
            { groupId = 11434, name = 'Aspidochelone' },
            { groupId = 11435, name = 'Behemoth' },
            { groupId = 11436, name = 'Sandworm' },
        },
    },

    Oblivion =
    {
        -- Aeonic-path capstone: seven waves of five sovereigns = 35 kills.
        -- A short stagger brings the formation in quickly. The mods sit
        -- just under the int16 mob-mod cap (~31k -- ATT 26000 is the headroom
        -- limit). Level nudged one cautious step to 230 (re-check that melee still
        -- lands before going higher). Only the deepest Prestige-geared full parties
        -- should clear this. Push future pain via HP / mods / counts, not level.
        wavesTotal      = 7,
        mobsPerWave     = 5,
        graceDelay      = 10,
        waveDelay       = 8,
        spawnStagger    = 2,
        minLevel        = 230,
        maxLevel        = 230,
        completionBonus = 2000,
        markBonus       = 20,
        hpBoost         = 18.0,
        mechanics =
        {
            name   = 'Void Sovereign',
            aoe    = { periodSec = 15, dmgPct = 5, msg = 'tears open a wave of void energy!' },
            drain  = { periodSec = 18, healPct = 1 },
            enrage = { sec = 190, att = 7000, haste = 150, msg = 'unseals its sovereign power!' },
        },
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
        -- Prime-path capstone: eight waves of five gods = 40 kills. HP and
        -- mechanics make each wave an endurance check with little breathing
        -- room. ATT 28000 sits just under the int16 mob-mod cap
        -- (~31k) with clamp headroom over the mob's innate attack. Level held at
        -- 235 (same reason as the tiers above: higher = mob EVASION outruns L99
        -- melee, un-fun not hard). This is the top flat-menu tier -- an 8th
        -- difficulty fills the customMenu's ~8-visible-option ceiling, so a 9th
        -- would need the difficulty menu paginated. Push future pain via HP /
        -- mods / counts.
        wavesTotal      = 8,
        mobsPerWave     = 5,
        graceDelay      = 10,
        waveDelay       = 8,
        spawnStagger    = 2,
        minLevel        = 235,
        maxLevel        = 235,
        completionBonus = 2800,
        markBonus       = 20,
        hpBoost         = 24.0,
        mechanics =
        {
            name   = 'The Unmade',
            aoe    = { periodSec = 14, dmgPct = 6, msg = 'unmakes the ground beneath the challengers!' },
            cc     = { periodSec = 28, effect = xi.effect.TERROR, power = 1, dur = 4, msg = 'reveals the end of all things!' },
            enrage = { sec = 180, att = 8500, haste = 180, msg = 'begins the final unmaking!' },
            phases = {
                { hp = 30, action = 'fury', att = 3500, haste = 100, msg = 'refuses its own destruction!' },
            },
        },
        mods =
        {
            [xi.mod.ATT]           = 28000,
            [xi.mod.ACC]           = 3600,
            [xi.mod.STR]           = 1400,
            [xi.mod.DEX]           = 1400,
            [xi.mod.HASTE_GEAR]    = 256,
            [xi.mod.DOUBLE_ATTACK] = 45,
            [xi.mod.TRIPLE_ATTACK] = 33,
            [xi.mod.QUAD_ATTACK]   = 16,
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
        -- Burtgang's proposal (2026-07-09): a SHORT, HIGH-DENSITY mark farm so
        -- solo/small groups aren't stuck waiting on trickle waves (report: hunt
        -- marks too slow solo). FEWER waves, MORE mobs per wave, big payout for
        -- clearing. 3 waves x 8 gods = 24 kills; +20/kill (480) + 1600 completion
        -- = ~2080 marks for a full clear -- the fastest marks/time on the board,
        -- paid for by fielding 8 simultaneous gods. Level held at 225 (the
        -- confirmed-hittable ceiling -- danger is the pile-on + Apocalypse-grade
        -- offense, not level/evasion). spawnStagger=2 so the 8 arrive fast (~14s)
        -- without an instant 8-god alpha strike. completionBonus is the main tuning
        -- dial. UNPLAYTESTED.
        -- NOTE: appended LAST in difficultyOrder (bit 256) per the append-only rule,
        -- even though it's shorter than the tiers above it -- it is a side-grade.
        wavesTotal      = 3,
        mobsPerWave     = 8,
        graceDelay      = 10,
        waveDelay       = 10,
        spawnStagger    = 2,
        minLevel        = 225,
        maxLevel        = 225,
        completionBonus = 1600,
        markBonus       = 20,
        hpBoost         = 12.0,
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
            -- Terror: ABYSSAL TERRORS -- apex Abyssea beasts for the 8-god pile-on.
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

-- Seconds between each mob spawn within a single wave.
-- 0 = all mobs spawn simultaneously (original behaviour).
-- Every live tier sets this explicitly; three seconds is the safe fallback for
-- future additions so a missing field cannot create minutes of dead air.
catalog.spawnStagger = 3

return catalog
