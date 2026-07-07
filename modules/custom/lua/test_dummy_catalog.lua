-----------------------------------
-- test_dummy_catalog.lua
-- Data for the Test Dummy NPC (modules/custom/lua/TestDummy.lua).
--
-- The Test Dummy is a training-target NPC at GM Home. Players talk
-- to it, pick a target, and a stationary dummy mob spawns next to the
-- NPC so they can verify gear / augment / DPS output against the
-- DEFENSIVE PROFILE of our real endgame encounters.
--
-- Every dummy:
--   - has a big HP pool (survives a full parse; Despawn when done)
--   - won't aggro (setAggressive(false)) or move (NO_MOVE = 1)
--   - won't drop loot / award capacity points
--   - hits back only at TICKLE tier and is therefore SAFE -- the base
--     pool is Leaping Lizzy (mob_groups 11355), a low-tier mob whose
--     outgoing damage stays trivial even at level 150 (the whole reason
--     that pool was chosen). The dummy's DEFENSE, not its offense, is
--     what we replicate.
--
-- WHAT MAKES A DUMMY "FAITHFUL": the engine hit-rate / damage formulas
-- key off the target's LEVEL and its DEF / EVA / MEVA / MDEF. So each
-- target below sets minLevel = maxLevel to the encounter's level and
-- applies that encounter's exact defensive mods AFTER spawn() (the same
-- way the live systems do). The dummy then takes damage / dodges /
-- resists exactly like the real thing, so your parse on it matches the
-- real fight. (GM Home is NOT a level-corrected zone, and neither
-- Provenance nor the Abyssea marks zones are either, so there is no
-- hidden zone penalty to account for -- the stat profile IS the fight.)
--
-- Targets come in two families, shown in submenus:
--   ASCENSION (Prestige) -- the 5 trial Courts. Each dummy mirrors the
--     APEX boss of that tier in prestige_catalog.lua trialScaling
--     (the wall of that Court). All are level 150 (the AV/PW baseline).
--   ABYSSEA NMs -- our custom marks-pop NMs. Each dummy mirrors the
--     per-content-tier profile in AbysseaMarks.lua zoneConfig
--     (atkDef -> DEF, accEva -> EVA + MEVA) at its level (135/145/155).
--
-- KEEP-IN-SYNC: the mod numbers below are COPIED from prestige_catalog.lua
-- (trialScaling apex bosses) and AbysseaMarks.lua (zoneConfig). If you
-- rebalance either system, refresh the matching block here so the dummy
-- keeps matching the real encounter. Mob source reuses Hunting League
-- mob_groups 11355 (registered in hunting_league_gm_home_mobs.sql) -- no
-- new SQL needed. xi.mod.* is available at require-time.
-----------------------------------

local catalog = {}

catalog.npcPos =
{
    zone     = 'Abdhaljs_Isle-Purgonorgo',
    zoneId   = 44,
    x        =  535.000,
    y        =  -3.000,
    z        = 568.000,
    rotation =  128,
}

-- Where the dummy mob appears when summoned. Pulled WELL away from the
-- tight NPC layout so combat at the dummy doesn't visually crowd the
-- lobby. Placed off to the east in open empty space.
catalog.spawnPos =
{
    x = 20.000,
    y = 0.000,
    z = -20.000,
    rotation = 192,
}

-- How far a summoned dummy may land from spawnPos. Each summon picks a
-- RANDOM point within this radius (in yalms) on the flat GM Home floor, so
-- dummies from different players -- or repeat spawns by one player -- scatter
-- instead of stacking on a single tile. Several people can park a dummy and
-- parse at the same time. The training area sits in open space east of the
-- NPC row; raise the radius for more spread, but not so far that dummies
-- drift back into the lobby or off the zone edge (8 stays comfortably clear).
catalog.spawnArea =
{
    radius = 8.0,
}

-- Every target entry sets:
--   label    - display name (kept short for the customMenu byte cap)
--   family   - 'asc' | 'aby' (drives which submenu it appears in)
--   minLevel /
--   maxLevel - REQUIRED, equal. Drives the level-based hit-rate / cRatio
--              floor; without it the engine spawns at level 255 = an
--              "unhittable garbage" mob (same caveat as GameMaster.lua).
--   hp       - testing HP pool (raw; setMaxHP + setHP after spawn()).
--   groupId  - mob_groups pool for the visual model + tickle base offense
--              (11355 = Leaping_Lizzy for ALL targets -> safe dummy).
--   mods     - { [xi.mod.X] = value } applied AFTER spawn() (pairs-iterated),
--              the encounter's DEFENSIVE profile. ONLY defense -- no ATT/ACC,
--              so the dummy can never threaten the tester.
catalog.tiers =
{
    -- ===== ASCENSION (Prestige) -- apex boss of each trialScaling tier =====
    -- All level 150. Mods mirror prestige_catalog.lua (DEF/EVASION/MEVA/MDEF).
    asc_nightmare =
    {
        label = 'Nightmare Court', family = 'asc',
        minLevel = 150, maxLevel = 150, hp =  50000000, groupId = 11355,
        mods = { [xi.mod.DEF] = 3300, [xi.mod.EVASION] = 1170, [xi.mod.MEVA] = 1260, [xi.mod.MDEF] = 1260 },  -- Odin (11372)
    },
    asc_voidwalkers =
    {
        label = 'Voidwalkers', family = 'asc',
        minLevel = 150, maxLevel = 150, hp =  75000000, groupId = 11355,
        mods = { [xi.mod.DEF] = 3987, [xi.mod.EVASION] = 1620, [xi.mod.MEVA] = 1530, [xi.mod.MDEF] = 1530 },  -- Qilin (11383)
    },
    asc_jailers =
    {
        label = 'The Jailers', family = 'asc',
        minLevel = 150, maxLevel = 150, hp = 100000000, groupId = 11355,
        mods = { [xi.mod.DEF] = 5775, [xi.mod.EVASION] = 1260, [xi.mod.MEVA] = 2160, [xi.mod.MDEF] = 2340 },  -- Jailer of Temperance (11386)
    },
    asc_lords =
    {
        label = 'Voidwalker Lords', family = 'asc',
        minLevel = 150, maxLevel = 150, hp = 150000000, groupId = 11355,
        mods = { [xi.mod.DEF] = 5500, [xi.mod.EVASION] = 1980, [xi.mod.MEVA] = 2520, [xi.mod.MDEF] = 2340 },  -- Maere (11389)
    },
    asc_worldsend =
    {
        label = "World's End", family = 'asc',
        minLevel = 150, maxLevel = 150, hp = 200000000, groupId = 11355,
        mods = { [xi.mod.DEF] = 6875, [xi.mod.EVASION] = 2340, [xi.mod.MEVA] = 3240, [xi.mod.MDEF] = 3240 },  -- Provenance Watcher (11392)
    },

    -- ===== ABYSSEA custom NMs -- per content tier =====
    -- Mods mirror AbysseaMarks.lua zoneConfig: atkDef -> DEF, accEva -> EVA + MEVA.
    aby_visions =
    {
        label = 'Visions', family = 'aby',
        minLevel = 135, maxLevel = 135, hp = 30000000, groupId = 11355,
        mods = { [xi.mod.DEF] = 3333, [xi.mod.EVA] = 2000, [xi.mod.MEVA] = 2000 },  -- Konschtat/Tahrongi/La Theine
    },
    aby_scars =
    {
        label = 'Scars', family = 'aby',
        minLevel = 145, maxLevel = 145, hp = 50000000, groupId = 11355,
        mods = { [xi.mod.DEF] = 6000, [xi.mod.EVA] = 3333, [xi.mod.MEVA] = 3333 },  -- Attohwa/Misareaux/Vunkerl
    },
    aby_heroes =
    {
        label = 'Heroes', family = 'aby',
        minLevel = 155, maxLevel = 155, hp = 75000000, groupId = 11355,
        mods = { [xi.mod.DEF] = 8666, [xi.mod.EVA] = 5000, [xi.mod.MEVA] = 5000 },  -- Altepa/Grauberg
    },
}

-- Stable submenu order.
catalog.ascensionOrder = { 'asc_nightmare', 'asc_voidwalkers', 'asc_jailers', 'asc_lords', 'asc_worldsend' }
catalog.abysseaOrder   = { 'aby_visions', 'aby_scars', 'aby_heroes' }

return catalog
