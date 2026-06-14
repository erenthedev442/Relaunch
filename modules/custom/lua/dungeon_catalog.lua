-----------------------------------
-- dungeon_catalog.lua
-- Config for the Dungeon System (see DungeonSystem.lua).
--
-- Each dungeon = a normally-empty LSB zone, dynamically populated on
-- entry. Trash + boss spawn around fixed points; player has a time
-- limit to kill the boss. Boss-kill = clear = infamy reward. Timer
-- expire / death / disconnect = abort, no reward.
--
-- All three launch zones were confirmed empty via the live DB
-- (zero mob_groups rows). No SQL changes needed - we reuse the HL
-- mob_groups (registered in zone 210 / GM_Home) via `groupZoneId`
-- so the engine resolves them without needing local zone rows.
--
-- Tuning knobs (everything in this file):
--   timeLimit         seconds to kill the boss. miss it -> abort.
--   infamyBase        flat reward on clear.
--   infamySpeedBonus  extra Infamy if cleared in the first half of
--                     the time window (encourages speedrunning).
--   trashCount        how many trash mobs spawn around the boss.
--   trashLevel        L override for trash (all use HL spec but
--                     mob:setMod for stats can scale them up later).
--   bossLevel         L override for the boss specifically.
--   warpIn            (x,y,z,rot) where the player materializes.
--   bossPos           (x,y,z,rot) where the boss spawns.
--   trashRing         ring of distances around bossPos where trash
--                     scatters at random angles.
--
-- =====================================================================
-- POSITION OVERRIDES (added 2026-05-30)
-- =====================================================================
-- Two ways to control where mobs spawn:
--
--   1. AXIS + DISTANCE (legacy, auto-computed)
--        progressionAxis = { dx, dz }            -- unit vector
--        waypoints[N].distance = 30/45/60/etc.   -- yalms from player
--        bossDistance          = 75              -- yalms from player
--      Y is locked to the player's Y. Works on flat single-floor
--      arenas; BREAKS on multi-elevation zones (mobs spawn under or
--      above the actual floor, looking 'off-map' to the player).
--
--   2. EXPLICIT POS (preferred for any non-flat zone)
--        waypoints[N].pos = { x = X, y = Y, z = Z }
--        bossPos          = { x = X, y = Y, z = Z, rot = R }
--      Coords used exactly as given. Y is honored, so waypoints/boss
--      can live on different elevations than the warp-in point. Mix
--      and match per waypoint -- one waypoint can use `pos`, another
--      can fall back to `distance`.
--
-- TUNING WORKFLOW for a dungeon spawning off-map:
--      1. Enter the dungeon, watch the [dungeon] spawn log lines.
--      2. Walk to where you WANT the boss / each waypoint to spawn.
--      3. Run `!pos` (player command) to read your current x,y,z,rot.
--      4. Paste into the dungeon entry as `bossPos = { x=..., y=..., z=..., rot=... }`
--         and `waypoints[N].pos = { x=..., y=..., z=... }`.
--      5. Re-enter the dungeon. Re-check the [dungeon] log -- the
--         line ends with `(explicit pos)` when override is honored.
-----------------------------------
local catalog = {}

-- ============================================================
-- INFAMY CURRENCY
-- ============================================================
-- Sits ABOVE the existing AF/Relic/Empy/HL currencies. Only earned
-- by clearing dungeons. Spent at the Infamy Vendor for BiS gear that
-- isn't available through the other systems.
catalog.currencyName = 'Infamy'
catalog.currencyCv   = 'Infamy'

-- ============================================================
-- BOUNDARIES OFF (player request — all dungeons)
-- ============================================================
-- When true, BOTH movement-restricting systems are disabled for EVERY
-- dungeon:
--   * the progression-gate "warding force" pushback (gatingOn), and
--   * the out-of-bounds warp-back-to-entry patrol.
-- Players move freely; mobs still spawn and (unless a dungeon sets
-- aggressive = false) still aggro and chase, and the boss + time limit are
-- unchanged. Set to false to restore per-dungeon gates / OOB rescue.
catalog.disableBoundaries = true

-- ============================================================
-- DUNGEON MASTER + INFAMY VENDOR NPC PLACEMENT
-- ============================================================
-- Both NPCs live at GM Home. Dungeon Master is on the existing custom-
-- NPC row (z=-15) but offset west of the others. Infamy Vendor sits
-- GM Home Activities cluster (z=-21): ExpCamp / Weekly Hunts /
-- Dungeon Master / Infamy Vendor.
catalog.dungeonMasterPos =
{
    zone     = 'GM_Home',
    zoneId   = 210,
    x        =  1.500,
    y        =  0.000,
    z        = -21.000,
    rotation =  128,
}

catalog.infamyVendorPos =
{
    zone     = 'GM_Home',
    zoneId   = 210,
    x        =  4.500,
    y        =  0.000,
    z        = -21.000,
    rotation =  128,
}

-- Where players warp back to after a clear / abort. Defaults to a few
-- yalms in front of the Dungeon Master so they land facing him.
catalog.exitWarp =
{
    zoneId   = 210,
    x        = -15.000,
    y        =   0.000,
    z        = -11.000,
    rotation = 128,
}

-- HL groupZoneId - the zone our existing 15 NM mob_groups are
-- registered under (210/GM_Home via hunting_league_gm_home_mobs.sql).
-- Used as the `groupZoneId` on every dungeon spawn so the engine
-- resolves the groupId from THIS table regardless of which zone the
-- mob actually appears in.
catalog.groupZoneId = 210

-- ============================================================
-- BOSS VISUAL SIZE
-- ============================================================
-- modelSize is a uint8 clamped to 0-3 in the engine. The client
-- renders the entity at progressively larger silhouettes:
--   0 - stock size (trash mobs always use this)
--   1 - small bump, barely noticeable
--   2 - clearly "boss-class" (the dungeon default)
--   3 - huge, can clip on tight zones
--
-- This catalog default applies to every dungeon's boss. Per-dungeon
-- override is available via `bossModelSize` on the dungeon entry -
-- set it to 3 on an open zone like Hall of the Gods if you want the
-- boss to read as truly massive, or back to 1 on a cramped arena.
catalog.bossModelSize = 2

-- ============================================================
-- DUNGEONS (3 launch dungeons)
-- ============================================================
-- Difficulty climbs: Whispering Halls (entry) -> Echoes of Adoulin
-- (mid) -> The Forgotten Bastion (apex). Infamy reward scales steeper
-- than linear - apex pays 5x the entry-tier reward.
--
-- HL groupIds reused:
--   11355  Leaping_Lizzy
--   11356  Valkurm_Emperor
--   11357  Tom_Tit_Tat
--   11358  Roc
--   11359  Bomb_Queen
--   11360  Aquarius
--   11361  Serket
--   11362  Vrtra
--   11363  Simurgh
--   11364  Nidhogg
--   11365  King_Behemoth
--   11366  Kirin
--   11367  Absolute_Virtue
--   11368  Pandemonium_Warden
--   11369  Shinryu
catalog.dungeons =
{
    -----------------------------------------------------------
    -- DUNGEON 1 - THE OUTER BASTION  (Lv99/110/120 trash / Lv135 boss)
    -----------------------------------------------------------
    --
    -- Zone-geometry strategy (lesson from the v1 launch bug):
    --   * warpIn uses the zone's KNOWN-GOOD entry coord (sourced
    --     from the existing mission scripts that already warp here).
    --   * Mobs spawn relative to the PLAYER'S position after the
    --     zone's onZoneIn ran, NOT at fixed catalog coords. The
    --     bossOffset gives an in-front-of-the-player vector; trash
    --     scatters in a ring around the boss.
    --   * This means we don't need to know zone DAT geometry -
    --     wherever the zone actually placed the player IS the arena
    --     center for that run.
    --
    -- Zone history:
    --   v1: Hall of the Gods (251) - rejected (wide-open SoA chamber,
    --       didn't read as "halls").
    --   v2: Monastic Cavern (150) - REJECTED, ~100+ visible native
    --       orcish mobs (15 active mob_groups).
    --   v3: Castle Zvahl Baileys (161) - scrubbed successfully but the
    --       multi-level castle geometry caused fall-through bugs when
    --       mobs were placed along the wrong vertical plane.
    --   v4: Dynamis-San_dOria_[D] (294) - Divergence version of the city.
    --       REJECTED (cause of the recurring login-stranding bug): the [D]
    --       instance zones are entered by setPos but only define
    --       onInstanceZoneIn, which does NOT reliably eject on a cold
    --       LOGIN. A player saved inside 294 when the server restarts or
    --       crashes mid-run cannot complete zone-in on relog -> black
    --       screen + perpetual "Player already logged in" loop. (Recovery:
    --       UPDATE chars SET pos_zone=210 ... WHERE pos_zone IN
    --       (294,295,296,297) moves any stranded char back to GM Home.)
    --   v5 (current): Dynamis-San_dOria (185) - the NORMAL city zone.
    --       Empty by default (native Dynamis mobs only spawn during an
    --       active hourglass event, which this server does not run), so the
    --       dungeon populates it cleanly. Crucially it has a real onZoneIn
    --       (xi.dynamis.zoneOnZoneIn) that EJECTS a sessionless arrival to
    --       the city via the standard Dynamis eject cutscene (cs 100) -- so
    --       a crash-mid-run no longer strands anyone: on relog they are
    --       cleanly bounced to town instead of frozen. DungeonSystem's
    --       onZoneIn override skips that eject ONLY while a live dungeon
    --       session exists. DO NOT point these dungeons back at the [D]
    --       (294-297) zones or the login-stranding bug returns.
    --
    -- The internal id stays 'whispering_halls' so existing player
    -- CharVars (clear counts, best times) and weekly-hunt objectives
    -- (Dungeon Diver) carry over without resetting.
    {
        id          = 'whispering_halls',
        label       = 'The Outer Bastion',
        description = 'The outer fortress of the dark king. Push east through the demon-haunted halls - the Doom Marquis holds the threshold of the inner keep.',
        zoneId      = xi.zone.DYNAMIS_SAN_DORIA,  -- 185
        zoneName    = 'Dynamis-San_dOria',
        gated       = false,  -- warding-force wall removed 2026-05-31; mobs still aggro & chase
        timeLimit   = 900,                           -- 15 minutes
        infamyBase  = 50,
        infamySpeedBonus = 25,

        -- Entry coord matches the regular Dynamis-San_dOria canonical
        -- entry (same physical city geometry). Adjust with !pos if the
        -- player lands at a different spot after a live run.
        warpIn      = { x = 161.838, y = -2.000, z = 161.673, rot = 93 },

        -- Retail mob positions (verified from mob_spawn_points.sql, zone 185).
        -- Path: NE gate plaza -> main road -> city square -> inner keep.
        waypoints =
        {
            -- More-mobs pass (2026-05-30): density raised. The 3
            -- original packs (verified mob_spawn_points coords) are interleaved
            -- with 3 NEW packs (A/B/C) placed at midpoints of the flat segments
            -- between them, so they sit on the same streets. !pos-fix any that
            -- land oddly after a live run.
            -- A (new) - entry plaza swarm
            { pos = { x = 147.930, y = -1.250, z = 120.340 }, count = 4, level = 99,  scatter = 4.0,
              groups = { 11355, 11357 },
              names  = { 'Lesser Demon', 'Skulking Imp' } },
            { pos = { x = 134.013, y = -0.500, z =  79.005 }, count = 4, level = 99,  scatter = 4.0,
              groups = { 11355, 11357 },
              names  = { 'Lesser Demon', 'Skulking Imp' } },
            -- B (new) - main road
            { pos = { x = 124.780, y = -0.010, z =  25.460 }, count = 4, level = 105, scatter = 4.0,
              groups = { 11359, 11361 },
              names  = { 'Bastion Cur', 'Shadowforged Knight' } },
            { pos = { x = 115.546, y =  0.483, z = -28.087 }, count = 4, level = 110, scatter = 4.0,
              groups = { 11359, 11361 },
              names  = { 'Shadowforged Knight', 'Bastion Cur' } },
            -- C (new) - approach to the inner square
            { pos = { x =  61.400, y =  0.990, z = -22.720 }, count = 3, level = 115, scatter = 4.0,
              groups = { 11358, 11362 },
              names  = { 'Hall-Haunt Revenant', 'Marquis-in-Waiting' } },
            { pos = { x =   7.254, y =  1.499, z = -17.358 }, count = 3, level = 120, scatter = 4.0,
              groups = { 11358, 11362 },
              names  = { 'Marquis-in-Waiting', 'Hall-Haunt Revenant' } },
        },
        bossPos = { x = -81.055, y = 1.500, z = -10.434, rot = 0 },
        bossLevel    = 135,
        bossGroup    = 11364,
        bossName     = 'The Doom Marquis',
        bossModelSize = 3,                           -- the one big boss: render huge

        -- Pre-boss NM elites (2026-05-30). Aggressive, un-bypassable gates
        -- on the final approach (frac = fraction from the last waypoint to
        -- the boss). hpMult is deliberately kept BELOW the boss so the Doom
        -- Marquis stays the hardest fight (its phases also out-class these).
        -- Bump hpMult / level after a live run if they read too soft.
        nms =
        {
            { frac = 0.28, level = 125, group = 11361, name = 'Bastion Vanguard',           hpMult = 1.2 },
            { frac = 0.50, level = 128, group = 11361, name = 'Bastion Dreadguard',         hpMult = 1.3 },
            { frac = 0.82, level = 133, group = 11362, name = 'Herald of the Doom Marquis', hpMult = 1.5 },
        },

        -- Phase 3 - entry-tier mechanics. Lighter touch: a single
        -- mid-fight reinforce + a low-HP enrage. Keeps the entry
        -- dungeon approachable while teaching the phase pattern.
        phases =
        {
            { hp = 50, action = 'add_spawn', groupId = 11355, count = 1,
              level = 99, name = 'Marquis Acolyte' },
            { hp = 25, action = 'enrage', att = 1500, haste = 75,
              message = 'The Doom Marquis casts off restraint!' },
        },
    },

    -----------------------------------------------------------
    -- DUNGEON 2 - THE VOIDWALKER ARENA  (Lv175 trash / Lv225 boss)
    -----------------------------------------------------------
    -- Dynamis-Bastok_[D] (295): Divergence version of Bastok. Same
    -- flat industrial streets; Mob population scrubbed via
    -- modules/custom/sql/dungeon_dynamis_bastok_d_scrub.sql.
    {
        id          = 'voidwalker_arena',
        label       = 'The Voidwalker Arena',
        description = 'A pocket arena suspended between worlds. Press inward - what answers your challenge waits in the dark.',
        zoneId      = xi.zone.DYNAMIS_BASTOK,  -- 186
        zoneName    = 'Dynamis-Bastok',
        gated       = false,  -- warding-force wall removed 2026-05-31; mobs still aggro & chase
        timeLimit   = 1080,
        -- M2 valley fix: D1 Mythic max = (50+25)*5 = 375; D2 Normal must exceed 375*1.10 = 412.5.
        -- Old values (100+50=150) caused a valley. Raised to 270+145=415 to clear the 10% threshold.
        infamyBase  = 270,
        infamySpeedBonus = 145,

        warpIn      = { x = 116.482, y = 0.994, z = -72.121, rot = 128 },

        -- Retail mob positions (verified from mob_spawn_points.sql, zone 186).
        -- Path: SE market -> central plaza -> upper district -> far quarter.
        waypoints =
        {
            -- More-mobs pass (2026-05-30): counts raised. Bastok's
            -- streets change elevation between packs, so only ONE new pack is
            -- interpolated here - on the FLAT wp2->wp3 run (both y=-0.5). The
            -- extra density elsewhere comes from higher counts on verified spots.
            { pos = { x =  66.825, y =  6.500, z = -30.591 }, count = 3, level = 120, scatter = 4.0,
              groups = { 11358, 11360 },
              names  = { 'Voidsworn Acolyte', 'Glass Stalker' } },
            { pos = { x =  17.423, y = -0.500, z = -78.738 }, count = 4, level = 135, scatter = 4.0,
              groups = { 11362, 11363 },
              names  = { 'Charred Sentinel', 'Glass Stalker' } },
            -- new - midpoint of the flat wp2->wp3 corridor
            { pos = { x =   1.770, y = -0.500, z = -20.000 }, count = 3, level = 142, scatter = 4.5,
              groups = { 11363, 11364 },
              names  = { 'Void Spawn', 'Charred Sentinel' } },
            { pos = { x = -13.875, y = -0.500, z =  38.749 }, count = 3, level = 150, scatter = 4.0,
              groups = { 11364 },
              names  = { 'Withered Knight', 'Ravenous Marauder' } },
        },
        bossPos = { x = -99.507, y = 7.263, z = 47.654, rot = 0 },
        bossLevel    = 170,
        bossGroup    = 11365,
        bossName     = 'The Void Maw',
        bossModelSize = 3,                           -- the one big boss: render huge

        -- Pre-boss NM elites (see Outer Bastion note).
        nms =
        {
            { frac = 0.28, level = 152, group = 11362, name = 'Void Acolyte-Lord', hpMult = 1.2 },
            { frac = 0.50, level = 158, group = 11363, name = 'Void Harbinger',    hpMult = 1.3 },
            { frac = 0.82, level = 165, group = 11360, name = 'Maw-Spawn Tyrant',  hpMult = 1.5 },
        },

        -- Phase 3 - mid-tier mechanics. Three phases plus a heal at
        -- low HP, no time enrage. Bridges the entry/apex difficulty.
        phases =
        {
            { hp = 70, action = 'buff', att = 1000, haste = 50,
              message = 'The Void Maw extends a horrid pseudopod!' },
            { hp = 40, action = 'dispel', count = 3,
              message = 'A wave of unbeing strips your protections!' },
            { hp = 15, action = 'heal', pct = 10,
              message = 'The Void Maw devours its own wounds!' },
        },
    },

    -----------------------------------------------------------
    -- DUNGEON 3 - THE EMPYREAL PARADOX  (Lv140/160/180 trash / Lv200 boss)
    -----------------------------------------------------------
    -- Dynamis-Windurst_[D] (296): Divergence version of Windurst.
    -- Open market streets - reliable flat geometry. Mob population
    -- scrubbed via modules/custom/sql/dungeon_dynamis_windurst_d_scrub.sql.
    --
    -- Zone swap history:
    --   2026-05-29: Cloister of Frost (203) -> Empyreal Paradox (36)
    --   2026-05-30: Empyreal Paradox (36) -> Dynamis-Windurst_[D] (296)
    --   Internal id stays 'cloister_of_sorrow' for CharVar / weekly-hunt compat.
    {
        id          = 'cloister_of_sorrow',
        label       = 'The Empyreal Paradox',
        description = 'A void-sphere suspended between worlds. Cut through three rings of the Forgotten; the Paradox itself waits at the center of nothing.',
        zoneId      = xi.zone.DYNAMIS_WINDURST,  -- 187
        zoneName    = 'Dynamis-Windurst',
        gated       = false,  -- warding-force wall removed 2026-05-31; mobs still aggro & chase
        timeLimit   = 1200,
        -- M2 valley fix: D2 Mythic max = (100+50)*5 = 750; D3 Normal must exceed 750*1.10 = 825.
        -- Old values (250+100=350) caused a valley. Raised to 600+230=830 to clear the 10% threshold.
        infamyBase  = 600,
        infamySpeedBonus = 230,

        warpIn      = { x = -221.988, y = 1.000, z = -120.184, rot = 0 },

        -- Retail mob positions (verified from mob_spawn_points.sql, zone 187).
        -- Path: NW bridge -> mid market -> city center -> southern plaza.
        waypoints =
        {
            -- More-mobs pass (2026-05-30): density raised. Windurst
            -- Dynamis is flat open market streets, so all three gaps get a NEW
            -- interpolated pack (1/2/3) at the segment midpoints between the
            -- verified spots. !pos-fix any that land oddly after a live run.
            -- 1 (new) - NW bridge approach
            { pos = { x = -191.700, y = -0.300, z = -120.100 }, count = 3, level = 140, scatter = 4.5,
              groups = { 11362, 11363 },
              names  = { 'Hollow Wisp', 'Voidsworn Watcher' } },
            { pos = { x = -161.459, y = -1.609, z = -120.014 }, count = 3, level = 140, scatter = 4.0,
              groups = { 11362, 11363 },
              names  = { 'Voidsworn Watcher', 'Hollow Wraith' } },
            -- 2 (new) - mid market
            { pos = { x = -104.300, y = -2.740, z = -114.500 }, count = 3, level = 150, scatter = 4.5,
              groups = { 11363, 11364 },
              names  = { 'Paradox Shade', 'Empyreal Drake' } },
            { pos = { x =  -47.137, y = -3.863, z = -108.998 }, count = 3, level = 160, scatter = 4.0,
              groups = { 11364, 11365 },
              names  = { 'Empyreal Drake', 'Paradox Tyrant' } },
            -- 3 (new) - turn toward the city center
            { pos = { x =  -42.500, y = -3.370, z =  -53.400 }, count = 3, level = 170, scatter = 4.5,
              groups = { 11365, 11366 },
              names  = { 'Paradox Tyrant', 'Forgotten Inquisitor' } },
            { pos = { x =  -37.834, y = -2.886, z =    2.252 }, count = 3, level = 180, scatter = 4.5,
              groups = { 11366, 11367 },
              names  = { 'Forgotten Inquisitor', 'Banner of the Forgotten', 'Throne Reaver' } },
        },
        bossPos = { x = 25.018, y = 0.090, z = 239.729, rot = 0 },
        bossLevel    = 200,
        -- Boss roulette: each run rolls one of these pairs. The
        -- catalog still ships bossGroup / bossName as a singular
        -- fallback for older dungeons; when bossGroups/bossNames is
        -- present and non-empty, the DungeonSystem prefers the plural
        -- form. To pair specific groups with specific names, just keep
        -- the arrays the same length and the indices matched - but
        -- that's optional; in flat form they're picked independently
        -- so the same boss model can show up with different names.
        bossGroup    = 11369,                       -- back-compat default
        bossName     = 'Paradoxon, the Forgotten',  -- back-compat default
        bossGroups   = { 11368, 11369 },            -- Pandemonium Warden / Shinryu
        bossNames    = { 'Paradoxon, the Forgotten', 'Azathoth, the Sundered Crown' },
        bossModelSize = 3,                           -- the one big boss: render huge

        -- Pre-boss NM elites. This dungeon's final approach is LONG (the
        -- boss sits far across the zone), so the NMs are pushed close to
        -- the boss plaza (high frac) to stay on verified-walkable ground.
        -- Re-place with !pos if either lands in geometry.
        nms =
        {
            { frac = 0.42, level = 182, group = 11365, name = 'Forgotten Arbiter',  hpMult = 1.2 },
            { frac = 0.65, level = 188, group = 11364, name = 'Forgotten Praetor',  hpMult = 1.3 },
            { frac = 0.88, level = 195, group = 11366, name = 'Herald of Oblivion', hpMult = 1.5 },
        },

        -- ============================================================
        -- PHASE 3 - Boss mechanics
        -- ============================================================
        -- HP-threshold phase triggers. Each entry fires once per run
        -- when the boss's HP% drops AT OR BELOW its `hp` threshold,
        -- walked in catalog order so a 75->50->25 chain fires sequentially
        -- even if the boss skips intermediate thresholds (e.g. a single
        -- big hit drops from 90% to 20%, all four would still fire on
        -- the same tick). Each `action` selects a handler from
        -- DungeonSystem.lua's bossActions table; remaining fields are
        -- handler params.
        --
        -- Phase actions available (see DungeonSystem.lua bossActions):
        --   buff       boss gains permanent stat mods (att/str/haste/dt)
        --   enrage     buff + visible chat message (the "big" buff)
        --   heal       boss heals N% of max HP (DPS check)
        --   aoe        AoE damage tick to the player
        --   dispel     strips N buffs from the player
        --   add_spawn  spawns N adds at boss position, force-aggroed
        phases =
        {
            { hp = 75, action = 'buff',      att =  800, message = 'Paradoxon wreathes itself in void energy!' },
            { hp = 50, action = 'add_spawn', groupId = 11366, count = 2,
              level = 150, name = 'Echo of the Forgotten' },
            { hp = 25, action = 'enrage',    att = 2500, haste = 100,
              message = 'Paradoxon refuses oblivion - its fury is unbound!' },
            { hp = 10, action = 'heal',      pct = 15,
              message = 'Paradoxon siphons the void itself to mend its wounds!' },
        },
        -- Enrage timer: if the fight runs past this many seconds, the
        -- boss erupts with massive permanent buffs. Drives time pressure
        -- separate from the dungeon's overall timeLimit. nil = no enrage.
        enrageAfter =
        {
            sec     = 600,    -- 10 minutes into the fight
            action  = 'enrage',
            att     = 4000,
            haste   = 150,
            message = 'TIME ENRAGE - Paradoxon channels the Sundering!',
        },
    },

    -----------------------------------------------------------
    -- DUNGEON 4 - THE ETERNAL THRONE  (Lv200/225/250 trash / Lv275 boss)
    -----------------------------------------------------------
    -- Dynamis-Jeuno_[D] (297): Divergence version of Jeuno.
    -- Grand boulevards and elevated bridges - the most open of the
    -- four Dynamis cities, ideal for the apex encounter. Mob population
    -- scrubbed via modules/custom/sql/dungeon_dynamis_jeuno_d_scrub.sql.
    -- (No IDs.lua GetFirstID exclusions needed - [D] zones have no IDs.lua.)
    --
    -- Zone swap 2026-05-30: Hall of the Gods (251) -> Dynamis-Jeuno_[D] (297).
    -- Reason: Hall of the Gods (0,0,0) warpIn was unverified - caused
    -- fall-off-map. Dynamis city entry coords are sourced from dynamis.lua.
    --
    -- Progression note: this dungeon is intentionally the hardest
    -- content on the server. Full BiS (Nyame / Infamy gear + +4 Reforge)
    -- is the expected completion baseline.
    {
        id          = 'eternal_throne',
        label       = 'The Eternal Throne',
        description = 'Where the Celestial Avatars once convened, only silence remains. Fight through the remnants of divine will to reach the seat of eternity itself.',
        zoneId      = xi.zone.DYNAMIS_JEUNO,  -- 188
        zoneName    = 'Dynamis-Jeuno',
        gated       = false,  -- warding-force wall removed 2026-05-31; mobs still aggro & chase
        timeLimit   = 1500,                      -- 25 minutes
        -- M2 valley fix: D3 Mythic max = (250+100)*5 = 1750; D4 Normal must exceed 1750*1.10 = 1925.
        -- Old values (400+200=600) caused a valley. Raised to 1400+530=1930 to clear the 10% threshold.
        infamyBase  = 1400,
        infamySpeedBonus = 530,

        -- Entry coord matches regular Dynamis-Jeuno canonical entry.
        -- y=10 is the elevated bridge platform.
        warpIn      = { x = 48.930, y = 10.002, z = -71.032, rot = 195 },

        -- Retail mob positions (verified from mob_spawn_points.sql, zone 188).
        -- Path: east bridge -> central boulevard -> upper tier -> throne hall.
        waypoints =
        {
            -- More-mobs pass (2026-05-30): density raised. Apex tier,
            -- so packs stay lean (count 3) since each mob is individually lethal.
            -- Two NEW packs (A/B) are interpolated on the flat street segments
            -- wp1->wp2 and wp2->wp3; the bridge descent (warpIn->wp1) is left
            -- clear because its big elevation drop makes midpoints unreliable.
            { pos = { x =  26.626, y = -0.599, z = -25.061 }, count = 3, level = 200, scatter = 5.0,
              groups = { 11362, 11363 },
              names  = { 'Throne Sentinel', 'Timeless Watcher' } },
            -- A (new) - central boulevard
            { pos = { x =  19.650, y =  0.830, z = -16.070 }, count = 3, level = 212, scatter = 5.0,
              groups = { 11363, 11364 },
              names  = { 'Throne Sentinel', 'Divine Adjudicator' } },
            { pos = { x =  12.683, y =  2.250, z =  -7.074 }, count = 3, level = 225, scatter = 5.0,
              groups = { 11364, 11365 },
              names  = { 'Divine Adjudicator', 'Celestial Drake' } },
            -- B (new) - upper tier approach
            { pos = { x =  -2.890, y =  2.330, z =  -7.650 }, count = 3, level = 237, scatter = 5.0,
              groups = { 11365, 11366 },
              names  = { 'Celestial Drake', 'Avatar\'s Revenant' } },
            { pos = { x = -18.457, y =  2.405, z =  -8.218 }, count = 3, level = 250, scatter = 5.0,
              groups = { 11366, 11367, 11368 },
              names  = { 'Avatar\'s Revenant', 'Eternal Inquisitor', 'The Vanquished' } },
        },
        bossPos = { x = -58.763, y = 5.400, z = -0.782, rot = 0 },
        bossLevel    = 275,

        -- Boss roulette: Absolute Virtue's ghost or the reborn Shinryu.
        -- Both use the Lv275 stat template - feel free to add a third
        -- entry if you add more HL NM groups later.
        bossGroup    = 11367,                         -- back-compat default
        bossName     = 'Throne of the Eternal',       -- back-compat default
        bossGroups   = { 11367, 11369 },              -- Absolute_Virtue / Shinryu
        bossNames    = { 'Throne of the Eternal', 'The Undying Storm' },
        bossModelSize = 3,                           -- the one big boss: render huge

        -- Pre-boss NM elites (see Outer Bastion note). Apex content - these
        -- sit on the Lv250 stat template; the boss (Lv275 + 4 phases +
        -- time enrage) remains the hardest fight on the server.
        nms =
        {
            { frac = 0.28, level = 256, group = 11365, name = 'Eternal Sentinel-Lord', hpMult = 1.2 },
            { frac = 0.50, level = 262, group = 11366, name = 'Eternal Praetorian',    hpMult = 1.3 },
            { frac = 0.82, level = 270, group = 11368, name = 'Warden of Eternity',    hpMult = 1.5 },
        },

        -- ============================================================
        -- PHASE - 4-phase boss that tests every system in the game
        -- ============================================================
        phases =
        {
            { hp = 80, action = 'buff',      att = 2000,  haste = 50,
              message = 'The Eternal Throne awakens to your challenge!' },
            { hp = 60, action = 'add_spawn', groupId = 11366, count = 2,
              level = 225, name = 'Fragment of Will',
              message = 'Shards of ancient divinity coalesce!' },
            { hp = 35, action = 'dispel',    count = 4,
              message = 'A wave of eternal silence strips your protection!' },
            { hp = 15, action = 'enrage',    att = 5000, haste = 200,
              message = 'THE ETERNAL THRONE REFUSES TO FALL - a blinding surge of divine fury!' },
        },
        enrageAfter =
        {
            sec     = 900,    -- 15 minutes into the fight (10 min before overall time limit)
            action  = 'enrage',
            att     = 8000,
            haste   = 300,
            message = 'TIME ENRAGE - The Eternal Throne channels eons of wrath!',
        },
    },

    -----------------------------------------------------------
    -- DUNGEON 5 - THE SHATTERED COAST  (parallel D1 entry tier)
    -----------------------------------------------------------
    -- Dynamis-Valkurm (39). Same difficulty envelope as The Outer
    -- Bastion (D1) so both zones can host simultaneous entry-tier
    -- groups. Coastal Valkurm aesthetic vs. D1's dark fortress halls.
    --
    -- warpIn sourced from dynamis.lua enterPos for xi.zone.VALKURM_DUNES.
    -- All waypoint / bossPos coords are PLACEHOLDERS - enter the dungeon
    -- and use !pos to pin each position to the actual floor, then paste
    -- the values back here.
    {
        id          = 'shattered_coast',
        label       = 'The Shattered Coast',
        description = 'A storm-wracked shore where ancient tidal demons have made their lair. Cut through the surf-haunted beach to reach the Hungering Tide before the sea reclaims you.',
        zoneId      = xi.zone.DYNAMIS_VALKURM,  -- 39
        zoneName    = 'Dynamis-Valkurm',
        gated       = false,
        timeLimit   = 900,               -- 15 min, mirrors D1
        infamyBase       = 50,
        infamySpeedBonus = 25,

        warpIn = { x = 100.000, y = -8.000, z = 131.000, rot = 47 },

        waypoints =
        {
            -- !pos NEEDED: all positions below are estimates from the floor Y.
            -- Enter dungeon, walk to desired spawn point, run !pos, update.
            { pos = { x =  90.0, y = -8.0, z = 105.0 }, count = 4, level = 99,  scatter = 4.0,
              groups = { 11355, 11357 },
              names  = { 'Tidal Wraith', 'Surf Specter' } },
            { pos = { x =  75.0, y = -8.0, z =  80.0 }, count = 4, level = 99,  scatter = 4.0,
              groups = { 11355, 11357 },
              names  = { 'Surf Specter', 'Tidal Wraith' } },
            { pos = { x =  58.0, y = -8.0, z =  55.0 }, count = 4, level = 105, scatter = 4.0,
              groups = { 11359, 11361 },
              names  = { 'Coastal Marauder', 'Deep-Sea Revenant' } },
            { pos = { x =  42.0, y = -8.0, z =  30.0 }, count = 4, level = 110, scatter = 4.0,
              groups = { 11359, 11361 },
              names  = { 'Deep-Sea Revenant', 'Coastal Marauder' } },
            { pos = { x =  25.0, y = -8.0, z =   5.0 }, count = 3, level = 115, scatter = 4.0,
              groups = { 11358, 11362 },
              names  = { 'Tide-Caller', 'Shoreline Tyrant' } },
            { pos = { x =   8.0, y = -8.0, z = -20.0 }, count = 3, level = 120, scatter = 4.0,
              groups = { 11358, 11362 },
              names  = { 'Shoreline Tyrant', 'Tide-Caller' } },
        },
        bossPos      = { x = -25.0, y = -8.0, z = -60.0, rot = 0 },
        bossLevel    = 135,
        bossGroup    = 11364,
        bossName     = 'The Hungering Tide',
        bossModelSize = 3,

        nms =
        {
            { frac = 0.28, level = 125, group = 11361, name = 'Tidecaller Vanguard',   hpMult = 1.2 },
            { frac = 0.50, level = 128, group = 11361, name = 'Surf Colossus',         hpMult = 1.3 },
            { frac = 0.82, level = 133, group = 11362, name = 'Admiral of the Deep',   hpMult = 1.5 },
        },

        phases =
        {
            { hp = 50, action = 'add_spawn', groupId = 11355, count = 1,
              level = 99, name = 'Tide Acolyte' },
            { hp = 25, action = 'enrage', att = 1500, haste = 75,
              message = 'The Hungering Tide surges with furious ocean energy!' },
        },
    },

    -----------------------------------------------------------
    -- DUNGEON 6 - THE FORSAKEN PENINSULA  (parallel D2 mid tier)
    -----------------------------------------------------------
    -- Dynamis-Buburimu (40). Same difficulty envelope as The Voidwalker
    -- Arena (D2). Ruined coastal peninsula aesthetic vs. D2's void arena.
    --
    -- warpIn sourced from dynamis.lua enterPos for xi.zone.BUBURIMU_PENINSULA.
    -- All waypoint / bossPos coords are PLACEHOLDERS - enter the dungeon
    -- and use !pos to pin each position to the actual floor, then paste
    -- the values back here.
    {
        id          = 'forsaken_peninsula',
        label       = 'The Forsaken Peninsula',
        description = 'Ancient ruins reclaimed by shadow and sea. Ruin-born sentinels hold every approach to the Forsaken Sovereign, who waits at the last standing tower on the edge of the world.',
        zoneId      = xi.zone.DYNAMIS_BUBURIMU,  -- 40
        zoneName    = 'Dynamis-Buburimu',
        gated       = false,
        timeLimit   = 1080,              -- 18 min, mirrors D2
        infamyBase       = 270,
        infamySpeedBonus = 145,

        warpIn = { x = 155.000, y = -1.000, z = -169.000, rot = 170 },

        waypoints =
        {
            -- !pos NEEDED: all positions below are estimates from the floor Y.
            { pos = { x = 130.0, y = -1.0, z = -148.0 }, count = 3, level = 120, scatter = 4.0,
              groups = { 11358, 11360 },
              names  = { 'Ruined Sentinel', 'Peninsula Shade' } },
            { pos = { x = 105.0, y = -1.0, z = -126.0 }, count = 4, level = 135, scatter = 4.0,
              groups = { 11362, 11363 },
              names  = { 'Ancient Marauder', 'Forsaken Watcher' } },
            { pos = { x =  80.0, y = -1.0, z = -104.0 }, count = 3, level = 142, scatter = 4.5,
              groups = { 11363, 11364 },
              names  = { 'Ruin Tyrant', 'Peninsula Arbiter' } },
            { pos = { x =  55.0, y = -1.0, z =  -80.0 }, count = 3, level = 150, scatter = 4.0,
              groups = { 11364 },
              names  = { 'Ancient Sovereign-Guard', 'Forsaken Warden' } },
        },
        bossPos      = { x = 20.0, y = -1.0, z = -45.0, rot = 0 },
        bossLevel    = 170,
        bossGroup    = 11365,
        bossName     = 'The Forsaken Sovereign',
        bossModelSize = 3,

        nms =
        {
            { frac = 0.28, level = 152, group = 11362, name = 'Ruin-Watcher Prime',         hpMult = 1.2 },
            { frac = 0.50, level = 158, group = 11363, name = 'Peninsula Arbiter-Lord',      hpMult = 1.3 },
            { frac = 0.82, level = 165, group = 11360, name = 'Herald of the Forsaken Shore',hpMult = 1.5 },
        },

        phases =
        {
            { hp = 70, action = 'buff', att = 1000, haste = 50,
              message = 'The Forsaken Sovereign draws power from the ancient ruins!' },
            { hp = 40, action = 'dispel', count = 3,
              message = 'Ruinous energies strip your protections!' },
            { hp = 15, action = 'heal', pct = 10,
              message = 'The Forsaken Sovereign absorbs the peninsula itself to mend its wounds!' },
        },
    },

    -----------------------------------------------------------
    -- DUNGEON 7 - THE DARK CITADEL  (parallel D3 upper-mid tier)
    -----------------------------------------------------------
    -- Dynamis-Xarcabard (135). Same difficulty envelope as The Empyreal
    -- Paradox (D3). Dark fortress aesthetic vs. D3's void-sphere.
    --
    -- warpIn sourced from dynamis.lua enterPos for xi.zone.XARCABARD.
    -- All waypoint / bossPos coords are PLACEHOLDERS - enter the dungeon
    -- and use !pos to pin each position to the actual floor, then paste
    -- the values back here. Xarcabard is flat (y~=0) so waypoints should
    -- land cleanly; the zone is large so spread generously.
    {
        id          = 'dark_citadel',
        label       = 'The Dark Citadel',
        description = 'The shadow-fortress at the edge of the known world. Shadow-bound legions defend every corridor leading to the Obsidian Throne, where an ancient power refuses to be forgotten.',
        zoneId      = xi.zone.DYNAMIS_XARCABARD,  -- 135
        zoneName    = 'Dynamis-Xarcabard',
        gated       = false,
        timeLimit   = 1200,              -- 20 min, mirrors D3
        infamyBase       = 600,
        infamySpeedBonus = 230,

        warpIn = { x = 569.312, y = -0.098, z = -270.158, rot = 90 },

        waypoints =
        {
            -- !pos NEEDED: all positions below are estimates stepping west
            -- along the citadel floor (y~=0). Xarcabard is a large open zone.
            { pos = { x = 540.0, y = 0.0, z = -260.0 }, count = 3, level = 140, scatter = 4.5,
              groups = { 11362, 11363 },
              names  = { 'Citadel Specter', 'Shadow-Bound Watcher' } },
            { pos = { x = 510.0, y = 0.0, z = -247.0 }, count = 3, level = 140, scatter = 4.0,
              groups = { 11362, 11363 },
              names  = { 'Shadow-Bound Watcher', 'Citadel Specter' } },
            { pos = { x = 480.0, y = 0.0, z = -233.0 }, count = 3, level = 150, scatter = 4.5,
              groups = { 11363, 11364 },
              names  = { 'Dark Citadel Shade', 'Void-Touched Sentinel' } },
            { pos = { x = 448.0, y = 0.0, z = -218.0 }, count = 3, level = 160, scatter = 4.0,
              groups = { 11364, 11365 },
              names  = { 'Citadel Drake', 'Dark Arbiter' } },
            { pos = { x = 415.0, y = 0.0, z = -200.0 }, count = 3, level = 170, scatter = 4.5,
              groups = { 11365, 11366 },
              names  = { 'Shadow Inquisitor', 'Citadel Tyrant' } },
            { pos = { x = 380.0, y = 0.0, z = -178.0 }, count = 3, level = 180, scatter = 4.5,
              groups = { 11366, 11367 },
              names  = { 'Shadow Sovereign-Guard', 'Abyss Throne Reaver' } },
        },
        bossPos      = { x = 330.0, y = 0.0, z = -145.0, rot = 0 },
        bossLevel    = 200,
        bossGroup    = 11369,
        bossName     = 'The Obsidian Throne',
        bossGroups   = { 11368, 11369 },
        bossNames    = { 'The Obsidian Throne', 'The Unbound Storm' },
        bossModelSize = 3,

        nms =
        {
            { frac = 0.42, level = 182, group = 11365, name = 'Citadel Harbinger',     hpMult = 1.2 },
            { frac = 0.65, level = 188, group = 11364, name = 'Shadow Arch-Praetor',   hpMult = 1.3 },
            { frac = 0.88, level = 195, group = 11366, name = 'Herald of the Abyss',   hpMult = 1.5 },
        },

        phases =
        {
            { hp = 75, action = 'buff',      att =  800, message = 'The Obsidian Throne writhes with shadow energy!' },
            { hp = 50, action = 'add_spawn', groupId = 11366, count = 2,
              level = 150, name = 'Citadel Echo' },
            { hp = 25, action = 'enrage',    att = 2500, haste = 100,
              message = 'The Obsidian Throne refuses oblivion - darkness is unbound!' },
            { hp = 10, action = 'heal',      pct = 15,
              message = 'The Obsidian Throne draws power from the shadow to mend itself!' },
        },
        enrageAfter =
        {
            sec     = 600,
            action  = 'enrage',
            att     = 4000,
            haste   = 150,
            message = 'TIME ENRAGE - The Dark Citadel awakens its full wrath!',
        },
    },

    -----------------------------------------------------------
    -- DUNGEON 8 - THE SUNKEN SPIRE  (parallel D4 apex tier)
    -----------------------------------------------------------
    -- Dynamis-Qufim (41). Same difficulty envelope as The Eternal Throne
    -- (D4). Abyssal island aesthetic vs. D4's grand Jeuno boulevard apex.
    --
    -- warpIn sourced from dynamis.lua enterPos for xi.zone.QUFIM_ISLAND.
    -- All waypoint / bossPos coords are PLACEHOLDERS - Qufim Island is
    -- a relatively compact zone; keep waypoints conservative and spread
    -- no more than 30-40 units per step until !pos verification.
    {
        id          = 'sunken_spire',
        label       = 'The Sunken Spire',
        description = 'A forgotten tower rising from a drowned island, haunted by abyssal guardians. Only the strongest groups have ever reached its peak - where the Drowned Eternal waits in the dark above the sea.',
        zoneId      = xi.zone.DYNAMIS_QUFIM,  -- 41
        zoneName    = 'Dynamis-Qufim',
        gated       = false,
        timeLimit   = 1500,              -- 25 min, mirrors D4
        infamyBase       = 1400,
        infamySpeedBonus = 530,

        warpIn = { x = -19.000, y = -17.000, z = 104.000, rot = 253 },

        waypoints =
        {
            -- !pos NEEDED: all positions below are estimates. Qufim Island
            -- is compact - if any position falls off-map, tighten the steps.
            { pos = { x = -8.0, y = -17.0, z =  84.0 }, count = 3, level = 200, scatter = 5.0,
              groups = { 11362, 11363 },
              names  = { 'Spire Warden', 'Abyssal Specter' } },
            { pos = { x =  5.0, y = -17.0, z =  64.0 }, count = 3, level = 212, scatter = 5.0,
              groups = { 11363, 11364 },
              names  = { 'Spire Sentinel', 'Deep Arbiter' } },
            { pos = { x = 18.0, y = -17.0, z =  44.0 }, count = 3, level = 225, scatter = 5.0,
              groups = { 11364, 11365 },
              names  = { 'Deep Arbiter', 'Abyssal Drake' } },
            { pos = { x = 32.0, y = -17.0, z =  24.0 }, count = 3, level = 237, scatter = 5.0,
              groups = { 11365, 11366 },
              names  = { 'Abyssal Drake', 'Spire Inquisitor' } },
            { pos = { x = 46.0, y = -17.0, z =   4.0 }, count = 3, level = 250, scatter = 5.0,
              groups = { 11366, 11367, 11368 },
              names  = { 'Spire Inquisitor', 'Abyssal Sovereign', 'The Submerged' } },
        },
        bossPos      = { x = 70.0, y = -17.0, z = -28.0, rot = 0 },
        bossLevel    = 275,
        bossGroup    = 11367,
        bossName     = 'The Drowned Eternal',
        bossGroups   = { 11367, 11369 },
        bossNames    = { 'The Drowned Eternal', 'The Abyssal Storm' },
        bossModelSize = 3,

        nms =
        {
            { frac = 0.28, level = 256, group = 11365, name = 'Spire Sentinel-Lord',         hpMult = 1.2 },
            { frac = 0.50, level = 262, group = 11366, name = 'Abyssal Praetorian',          hpMult = 1.3 },
            { frac = 0.82, level = 270, group = 11368, name = 'Warden of the Sunken Spire',  hpMult = 1.5 },
        },

        phases =
        {
            { hp = 80, action = 'buff',      att = 2000, haste = 50,
              message = 'The Drowned Eternal rises from the deep!' },
            { hp = 60, action = 'add_spawn', groupId = 11366, count = 2,
              level = 225, name = 'Fragment of the Deep',
              message = 'Abyssal shards coalesce from the darkness!' },
            { hp = 35, action = 'dispel',    count = 4,
              message = 'A wave of abyssal silence strips your protection!' },
            { hp = 15, action = 'enrage',    att = 5000, haste = 200,
              message = 'THE DROWNED ETERNAL REFUSES TO SINK - a crushing surge of abyssal fury!' },
        },
        enrageAfter =
        {
            sec     = 900,
            action  = 'enrage',
            att     = 8000,
            haste   = 300,
            message = 'TIME ENRAGE - The Sunken Spire drowns the world in wrath!',
        },
    },
}

-- ============================================================
-- COMBAT MODS APPLIED TO DUNGEON MOBS
-- ============================================================
-- Trash and boss get the same difficulty-scaled mod profile, indexed
-- by their level. Mirrors the Hunting League / Reforge approach so
-- mobs at the same level feel consistent across systems.
--
-- BOSS gets an additional HP boost on top of the trash baseline; trash
-- stays one-shottable-with-effort (3-5s per kill for a geared L99).
catalog.levelMods =
{
    -- Sub-150 breakpoints. Added 2026-05-30: the entry dungeon (The Outer
    -- Bastion, Lv99-135) and the early trash of dungeons 2-3 sit BELOW the
    -- old Lv150 floor, so modsForLevel() returned nil and those mobs spawned
    -- with raw base stats - no ATT, no HP boost, no bossHpMultiplier. That's
    -- why the entry boss was a pushover. These rows extrapolate down from
    -- [150] so the low end has a real (but gentle) difficulty ramp. Entry
    -- tier is still meant to be soloable with gear - tune upward if it reads
    -- too soft after a live run.
    [99] = {
        hpBoost = 1.5,
        mods = {
            [xi.mod.ATT]           = 1000, [xi.mod.ACC]           = 550,
            [xi.mod.STR]           = 40,   [xi.mod.DEX]           = 40,
            [xi.mod.HASTE_GEAR]    = 50,   [xi.mod.DOUBLE_ATTACK] = 3,
        },
    },
    [110] = {
        hpBoost = 1.8,
        mods = {
            [xi.mod.ATT]           = 1400, [xi.mod.ACC]           = 640,
            [xi.mod.STR]           = 55,   [xi.mod.DEX]           = 55,
            [xi.mod.HASTE_GEAR]    = 75,   [xi.mod.DOUBLE_ATTACK] = 5,
        },
    },
    [120] = {
        hpBoost = 2.0,
        mods = {
            [xi.mod.ATT]           = 1800, [xi.mod.ACC]           = 720,
            [xi.mod.STR]           = 70,   [xi.mod.DEX]           = 70,
            [xi.mod.HASTE_GEAR]    = 100,  [xi.mod.DOUBLE_ATTACK] = 6,
        },
    },
    [135] = {
        hpBoost = 2.5,
        mods = {
            [xi.mod.ATT]           = 2200, [xi.mod.ACC]           = 820,
            [xi.mod.STR]           = 90,   [xi.mod.DEX]           = 90,
            [xi.mod.HASTE_GEAR]    = 130,  [xi.mod.DOUBLE_ATTACK] = 8,
        },
    },
    [140] = {
        hpBoost = 2.7,
        mods = {
            [xi.mod.ATT]           = 2350, [xi.mod.ACC]           = 860,
            [xi.mod.STR]           = 95,   [xi.mod.DEX]           = 95,
            [xi.mod.HASTE_GEAR]    = 140,  [xi.mod.DOUBLE_ATTACK] = 9,
        },
    },
    [150] = {
        hpBoost = 3,
        mods = {
            [xi.mod.ATT]           = 2500, [xi.mod.ACC]           = 900,
            [xi.mod.STR]           = 100,  [xi.mod.DEX]           = 100,
            [xi.mod.HASTE_GEAR]    = 150,  [xi.mod.DOUBLE_ATTACK] = 10,
        },
    },
    [175] = {
        hpBoost = 4,
        mods = {
            [xi.mod.ATT]           = 4000, [xi.mod.ACC]           = 1200,
            [xi.mod.STR]           = 200,  [xi.mod.DEX]           = 200,
            [xi.mod.HASTE_GEAR]    = 200,  [xi.mod.DOUBLE_ATTACK] = 15,
            [xi.mod.TRIPLE_ATTACK] = 3,
        },
    },
    [200] = {
        hpBoost = 5,
        mods = {
            [xi.mod.ATT]           = 6000, [xi.mod.ACC]           = 1500,
            [xi.mod.STR]           = 300,  [xi.mod.DEX]           = 300,
            [xi.mod.HASTE_GEAR]    = 250,  [xi.mod.DOUBLE_ATTACK] = 20,
            [xi.mod.TRIPLE_ATTACK] = 8,
        },
    },
    [225] = {
        hpBoost = 8,
        mods = {
            [xi.mod.ATT]           = 8000, [xi.mod.ACC]           = 1750,
            [xi.mod.STR]           = 450,  [xi.mod.DEX]           = 450,
            [xi.mod.HASTE_GEAR]    = 280,  [xi.mod.DOUBLE_ATTACK] = 23,
            [xi.mod.TRIPLE_ATTACK] = 10,
        },
    },
    [250] = {
        hpBoost = 12,
        mods = {
            [xi.mod.ATT]           = 12000, [xi.mod.ACC]           = 2200,
            [xi.mod.STR]           = 600,  [xi.mod.DEX]           = 600,
            [xi.mod.HASTE_GEAR]    = 300,  [xi.mod.DOUBLE_ATTACK] = 27,
            [xi.mod.TRIPLE_ATTACK] = 13,
        },
    },
    -- Level 275 - Eternal Throne boss tier. Substantially harder than
    -- Lv250 trash: tighter accuracy requirement, higher raw damage, more
    -- multihit. Intended to require near-full BiS gear to clear reliably.
    [275] = {
        hpBoost = 20,
        mods = {
            [xi.mod.ATT]           = 18000, [xi.mod.ACC]           = 2800,
            [xi.mod.STR]           = 900,  [xi.mod.DEX]           = 900,
            [xi.mod.HASTE_GEAR]    = 320,  [xi.mod.DOUBLE_ATTACK] = 30,
            [xi.mod.TRIPLE_ATTACK] = 16,
        },
    },
}

-- Boss gets EXTRA HP on top of the level template. Multiplied with the
-- level's hpBoost.
--
-- Tuned 2026-05-28: was 2.0 (so Lv200 boss = 5x x 2x = 10x base HP,
-- ~150k HP - unkillable in the time limit solo). 1.2 is just enough
-- that the boss feels distinct from the trash without being a sponge.
-- Combined with the level downshifts in each dungeon (apex boss now
-- Lv200 instead of Lv250), a geared Lv99 should be able to clear the
-- entry-tier boss in ~5 min, apex in ~10-12 min.
catalog.bossHpMultiplier = 1.2

-- ============================================================
-- PHASE 1 - PER-RUN AFFIXES
-- ============================================================
-- Every dungeon run rolls 1-2 affixes from this pool. Each affix is a
-- self-contained data row describing:
--   id            unique short string (used in chat / save state)
--   label         display name shown in the entry banner
--   kind          'positive' | 'negative' | 'mixed'  (UI flavour only)
--   description   one-line player-facing explanation
--   applyBoss     optional fn(mob) -> applies engine mods to the boss
--                 right after the level template is applied. Cheap
--                 mod-only effects only - anything that needs scripted
--                 AI belongs in a later phase.
--   applyTrash   optional fn(mob) -> applied to each trash mob
--   applySession optional fn(sess) -> mutates the session table itself
--                 (e.g. tweaks timeLimit). Runs once at session start
--                 BEFORE the timer is armed.
--   rewardMult    multiplier applied to the dungeon's Infamy reward
--                 on clear. Negative affixes give >1.0 (more reward
--                 because the run was harder); positive affixes give
--                 <1.0 (less reward because the run was easier).
--
-- A run rolls catalog.affixCountMin .. catalog.affixCountMax affixes.
-- Final reward multiplier = product of all rolled affixes' rewardMult.
-- e.g. Voracious (1.15) x Mighty (1.20) = 1.38x reward on clear.
-- ============================================================
catalog.affixCountMin = 1
catalog.affixCountMax = 2

-- If true, only show affix-clear bonuses to the player on completion.
-- If false (default), also print the per-affix descriptions in the
-- entry banner.
catalog.affixesQuiet = false

catalog.affixes =
{
    -- =================== NEGATIVE (boss harder, more reward) ===================
    {
        id          = 'voracious',
        label       = 'Voracious',
        kind        = 'negative',
        description = 'The boss regenerates rapidly - sustain the DPS.',
        applyBoss   = function(mob)
            mob:setMod(xi.mod.REGEN, 100)
        end,
        rewardMult  = 1.15,
    },
    {
        id          = 'mighty',
        label       = 'Mighty',
        kind        = 'negative',
        description = "The boss's strikes land like hammers.",
        applyBoss   = function(mob)
            mob:setMod(xi.mod.ATT, 1500)
            mob:setMod(xi.mod.STR, 75)
        end,
        rewardMult  = 1.20,
    },
    {
        id          = 'frenzied',
        label       = 'Frenzied',
        kind        = 'negative',
        description = "The boss attacks faster than the eye can follow.",
        applyBoss   = function(mob)
            -- HASTE_GEAR caps client-side at 25% (256 mod = 25%).
            -- Stacking on top of the level template's haste pushes
            -- the boss right to the engine cap.
            mob:setMod(xi.mod.HASTE_GEAR, 100)
            mob:setMod(xi.mod.DOUBLE_ATTACK, 10)
        end,
        rewardMult  = 1.15,
    },
    {
        id          = 'hardy',
        label       = 'Hardy',
        kind        = 'negative',
        description = 'The boss has a vastly inflated health pool.',
        applyBoss   = function(mob)
            local hp = mob:getMaxHP()
            mob:setMaxHP(math.floor(hp * 1.5))
            mob:setHP(mob:getMaxHP())
        end,
        rewardMult  = 1.25,
    },
    {
        id          = 'vigilant',
        label       = 'Vigilant',
        kind        = 'negative',
        description = 'The boss never misses - no relying on evasion.',
        applyBoss   = function(mob)
            mob:setMod(xi.mod.ACC, 500)
        end,
        rewardMult  = 1.10,
    },
    {
        id          = 'evasive',
        label       = 'Evasive',
        kind        = 'negative',
        description = 'The boss is uncannily slippery.',
        applyBoss   = function(mob)
            mob:setMod(xi.mod.EVA, 400)
        end,
        rewardMult  = 1.10,
    },
    {
        id          = 'fortified',
        label       = 'Fortified',
        kind        = 'negative',
        description = "The boss's hide blunts incoming blows.",
        applyBoss   = function(mob)
            mob:setMod(xi.mod.PHYS_DMG_TAKEN, -10)
            mob:setMod(xi.mod.MAGIC_DMG_TAKEN, -10)
        end,
        rewardMult  = 1.20,
    },
    {
        id          = 'overgrown',
        label       = 'Overgrown',
        kind        = 'negative',
        description = 'Trash mobs are tougher than usual.',
        applyTrash  = function(mob)
            local hp = mob:getMaxHP()
            mob:setMaxHP(math.floor(hp * 1.5))
            mob:setHP(mob:getMaxHP())
            mob:setMod(xi.mod.ATT, 500)
        end,
        rewardMult  = 1.10,
    },
    {
        id          = 'speedy',
        label       = 'Speedy',
        kind        = 'negative',
        description = 'Time is short - the arena devours the slow.',
        applySession = function(sess)
            sess.timeLimitOverride = math.floor(sess.dungeon.timeLimit * 0.75)
        end,
        rewardMult  = 1.30,
    },

    -- =================== POSITIVE (boss easier, less reward) ===================
    {
        id          = 'fragile',
        label       = 'Fragile',
        kind        = 'positive',
        description = 'The boss is reeling - its HP is dramatically reduced.',
        applyBoss   = function(mob)
            local hp = mob:getMaxHP()
            mob:setMaxHP(math.floor(hp * 0.5))
            mob:setHP(mob:getMaxHP())
        end,
        rewardMult  = 0.70,
    },
    {
        id          = 'sluggish',
        label       = 'Sluggish',
        kind        = 'positive',
        description = 'The boss moves and strikes as if mired in tar.',
        applyBoss   = function(mob)
            mob:setMod(xi.mod.HASTE_GEAR, -200)
            mob:setMod(xi.mod.MOVE, -25)
        end,
        rewardMult  = 0.80,
    },
    {
        id          = 'exposed',
        label       = 'Exposed',
        kind        = 'positive',
        description = 'The boss has a glaring weakness - damage taken is doubled.',
        applyBoss   = function(mob)
            mob:setMod(xi.mod.PHYS_DMG_TAKEN, 50)
            mob:setMod(xi.mod.MAGIC_DMG_TAKEN, 50)
        end,
        rewardMult  = 0.60,
    },
    {
        id          = 'lengthy',
        label       = 'Lengthy',
        kind        = 'positive',
        description = 'Time bends - the run window stretches 50% longer.',
        applySession = function(sess)
            sess.timeLimitOverride = math.floor(sess.dungeon.timeLimit * 1.5)
        end,
        rewardMult  = 0.85,
    },

    -- =================== MIXED (interesting trade-offs) ===================
    {
        id          = 'glasscannon',
        label       = 'Glass Cannon',
        kind        = 'mixed',
        description = 'Boss hits hard but is just as easy to break.',
        applyBoss   = function(mob)
            mob:setMod(xi.mod.ATT, 2000)
            mob:setMod(xi.mod.PHYS_DMG_TAKEN, 25)
            mob:setMod(xi.mod.MAGIC_DMG_TAKEN, 25)
        end,
        rewardMult  = 1.10,
    },
    {
        id          = 'bountiful',
        label       = 'Bountiful',
        kind        = 'positive',
        description = 'The dungeon overflows with riches - Infamy is increased.',
        -- Pure reward modifier. No engine effect, no extra difficulty,
        -- just a happy roll. Rare-feeling because of the steep mult.
        rewardMult  = 1.50,
    },

    -- DungeonSystem.lua reads modType and param; complex affixes like boss_enrage are implemented progressively as the system grows.

    -- =================== NEGATIVE (boss harder, more reward) ===================
    {
        id      = 'enrage_timer',
        label   = 'Enraged',
        desc    = 'Boss enters a frenzy after 60% HP, gaining +50% ATT and Haste.',
        modType = 'boss_enrage',
        param   = { hpTrigger = 0.6, attBoost = 5000, hasteBoost = 150 },
    },
    {
        id      = 'regen_aura',
        label   = 'Regenerating',
        desc    = 'The boss regenerates 1% HP per second when not taking damage.',
        modType = 'boss_regen',
        param   = { regenPct = 1, breakOnHit = true },
    },
    {
        id      = 'shadow_clones',
        label   = 'Shadow Clones',
        desc    = 'Trash mobs are joined by illusory copies — double trash count.',
        modType = 'trash_multiplier',
        param   = { multiplier = 2 },
    },
    {
        id      = 'time_pressure',
        label   = 'Time Crunch',
        desc    = 'Time limit reduced by 30%.',
        modType = 'time_reduction',
        param   = { reductionPct = 0.30 },
    },
    {
        id      = 'debuff_aura',
        label   = 'Cursed Ground',
        desc    = 'All players suffer Slow and Poison throughout the dungeon.',
        modType = 'player_debuff',
        param   = { effects = { 'slow', 'poison' } },
    },

    -- =================== POSITIVE (make clears rewarding) ===================
    {
        id      = 'gold_fever',
        label   = 'Gold Fever',
        desc    = 'Infamy reward +50% on clear.',
        modType = 'infamy_bonus',
        param   = { bonusPct = 0.50 },
    },
    {
        id      = 'double_boss',
        label   = 'Twin Threat',
        desc    = 'Boss is accompanied by a second (weaker) copy — but Infamy +25% if both fall.',
        modType = 'dual_boss',
        param   = { secondaryHpMult = 0.4, infamyBonus = 0.25 },
    },
    {
        id      = 'speed_bonus',
        label   = 'Blitz Mode',
        desc    = 'Speed-clear bonus doubled this run.',
        modType = 'speed_multiplier',
        param   = { multiplier = 2 },
    },

    -- =================== MIXED (harder AND rewarding) ===================
    {
        id      = 'elite_trash',
        label   = 'Elite Guards',
        desc    = 'Trash mobs are HNM-strength — but each trash kill grants +5 Infamy.',
        modType = 'elite_trash',
        param   = { trashHpMult = 3.0, trashAttMult = 2.5, bonusInfamyPerTrash = 5 },
    },
    {
        id      = 'chaotic_spawn',
        label   = 'Chaotic Summoning',
        desc    = 'Boss randomly summons adds. Kill all adds for +30% Infamy.',
        modType = 'boss_adds',
        param   = { addCount = 3, infamyBonusIfKilled = 0.30 },
    },
}

-- ============================================================
-- PHASE 2 - DIFFICULTY TIERS  (Normal / Hard / Mythic)
-- ============================================================
-- Every dungeon now has three tier variants. Players pick a tier
-- after picking a dungeon; the higher tiers gate on prior clears and
-- (for Mythic) a weekly key.
--
-- Each tier multiplies the base dungeon numbers:
--   hpMult        scales every spawned mob's max HP (boss + trash)
--   attMult       multiplies the level-template ATT mod additively-
--                 in-spirit (we apply a flat bonus = base * (mult-1))
--   timeMult      multiplies the dungeon's timeLimit
--   infamyMult    multiplies the dungeon's infamy reward (before affixes)
--   affixCountMin
--   affixCountMax pick range when rolling affixes for this tier
--   mythicAffixPool   when true, the affix roller also draws from
--                     catalog.mythicAffixes (the Tyrannical pool)
--   unlockRequires    nil for Normal (always open). For Hard/Mythic:
--                     { tier = 'normal', clears = N } means the player
--                     needs N clears of the named tier of THIS dungeon
--                     to unlock this tier.
--   weekly            when true, this tier requires a weekly key. Each
--                     player gets ONE clear of this tier per ISO week
--                     per dungeon, tracked via Dungeon_MythicWeek_<id>.
--
-- Reward math at clear time:
--   rawInfamy   = (infamyBase + maybeSpeedBonus) * tier.infamyMult
--   finalInfamy = rawInfamy * (product of affix rewardMults)
-- ============================================================
catalog.tiers =
{
    normal =
    {
        id            = 'normal',
        label         = 'Normal',
        description   = 'The dungeon as designed. Soloable with gear.',
        hpMult        = 1.0,
        attMult       = 1.0,
        timeMult      = 1.0,
        infamyMult    = 1.0,
        affixCountMin = 1,
        affixCountMax = 2,
        mythicAffixPool = false,
        unlockRequires  = nil,    -- always open
        weekly          = false,
    },
    hard =
    {
        id            = 'hard',
        label         = 'Hard',
        description   = 'Boss tougher and hits harder. Group recommended.',
        hpMult        = 1.5,
        attMult       = 1.3,
        timeMult      = 1.25,
        infamyMult    = 2.0,
        affixCountMin = 1,
        affixCountMax = 2,
        mythicAffixPool = false,
        unlockRequires  = { tier = 'normal', clears = 1 },
        weekly          = false,
    },
    mythic =
    {
        id            = 'mythic',
        label         = 'Mythic',
        description   = 'Apex challenge. Weekly key. Best loot, brutal fight.',
        hpMult        = 2.5,
        attMult       = 1.8,
        timeMult      = 0.85,
        infamyMult    = 5.0,
        affixCountMin = 2,
        affixCountMax = 3,
        mythicAffixPool = true,
        unlockRequires  = { tier = 'hard', clears = 5 },
        weekly          = true,
    },
}

-- Menu/display order. Loops that walk tiers should use this rather
-- than pairs(catalog.tiers) so the order is deterministic.
catalog.tierOrder = { 'normal', 'hard', 'mythic' }

-- ============================================================
-- MYTHIC AFFIXES  (Tyrannical pool - drawn only at Mythic tier)
-- ============================================================
-- These are nastier than the base pool. They roll only when the
-- chosen tier has mythicAffixPool = true. The base pool still rolls
-- too - Mythic just gets a larger total selection (typically 2-3
-- affixes per run vs 1-2 for Normal/Hard) AND a chance at these.
catalog.mythicAffixes =
{
    {
        id          = 'tyrannical',
        label       = 'Tyrannical',
        kind        = 'negative',
        description = 'The boss strikes at the peak of its power.',
        applyBoss   = function(mob)
            mob:setMod(xi.mod.ATT, 3000)
            mob:setMod(xi.mod.STR, 150)
            mob:setMod(xi.mod.DOUBLE_ATTACK, 15)
        end,
        rewardMult  = 1.40,
    },
    {
        id          = 'unrelenting',
        label       = 'Unrelenting',
        kind        = 'negative',
        description = 'The boss shrugs off blows that would fell lesser foes.',
        applyBoss   = function(mob)
            mob:setMod(xi.mod.PHYS_DMG_TAKEN, -25)
            mob:setMod(xi.mod.MAGIC_DMG_TAKEN, -25)
        end,
        rewardMult  = 1.35,
    },
    {
        id          = 'inescapable',
        label       = 'Inescapable',
        kind        = 'negative',
        description = 'Time itself rebels - the window is brutally short.',
        applySession = function(sess)
            -- Multiplies the already-tier-adjusted limit. Tier.timeMult
            -- runs first; this slashes whatever's left. So Mythic
            -- (0.85x) + Inescapable (0.6x) = ~0.51x of base = brutal.
            sess.timeLimitOverride = math.floor((sess.timeLimitOverride or
                sess.dungeon.timeLimit * (sess.tier and sess.tier.timeMult or 1.0)) * 0.6)
        end,
        rewardMult  = 1.50,
    },
    {
        id          = 'apex',
        label       = 'Apex Predator',
        kind        = 'negative',
        description = 'Trash mobs swarm with apex fury.',
        applyTrash  = function(mob)
            local hp = mob:getMaxHP()
            mob:setMaxHP(math.floor(hp * 1.5))
            mob:setHP(mob:getMaxHP())
            mob:setMod(xi.mod.ATT, 1500)
            mob:setMod(xi.mod.HASTE_GEAR, 50)
        end,
        rewardMult  = 1.20,
    },
    {
        id          = 'titanic',
        label       = 'Titanic',
        kind        = 'negative',
        description = 'The boss is vastly inflated - bring sustain.',
        applyBoss   = function(mob)
            local hp = mob:getMaxHP()
            mob:setMaxHP(math.floor(hp * 2.0))
            mob:setHP(mob:getMaxHP())
        end,
        rewardMult  = 1.45,
    },
}

-- ============================================================
-- PHASE 7 - MYTHIC+ KEYSTONES  (endless key-level push)
-- ============================================================
-- Open-ended difficulty ABOVE Mythic. Unlocked per dungeon by 1
-- Mythic clear of that dungeon. Each dungeon tracks a key level
-- (Dungeon_KeyLevel_<id>, min 1). A keystone run spawns the dungeon
-- at Mythic-grade base scaling grown per key level, with a
-- DETERMINISTIC weekly affix set (rotation below) instead of the
-- random roller - everyone fights the same combo all week, and the
-- combo changes every Monday 00:00 UTC (same anchor as the Mythic
-- weekly key).
--
-- Every clear is "timed" by construction (timeout ENDS the run), so
-- a clear upgrades the key by +1/+2/+3 based on how much clock was
-- used; any failed run (death/timeout/abort/leave) depletes it by 1
-- (floor: minLevel). Score = highest level cleared, per dungeon
-- (Dungeon_KeyBest_<id>) + global max (Dungeon_KeyBest) for the
-- website leaderboard. A new personal best pays a one-time bonus of
-- infamyBase * pbBonusMult.
--
-- Economy guard: infamyMult starts at 3.0 and grows +15%/level but is
-- CAPPED at the Mythic 5.0. Keystone runs are unlimited, so past ~M+6
-- the chase is score + PB bonuses, not an ever-growing Infamy faucet.
-- The weekly Mythic key (one-shot 5x jackpot) is untouched and never
-- burns on keystone runs.
catalog.keystone =
{
    enabled     = true,
    label       = 'Mythic+',
    labelShort  = 'M+',
    description = 'Endless keystone push. Clears upgrade the key; failures deplete it.',

    -- Per-dungeon unlock, checked against the same per-tier clear
    -- counters Phase 2 writes (Dungeon_Clears_<id>_mythic).
    unlockRequires = { tier = 'mythic', clears = 1 },

    -- Level-1 baseline (matches the Mythic tier row except infamy).
    base = { hpMult = 2.5, attMult = 1.8, timeMult = 0.85, infamyMult = 3.0 },

    -- Linear growth per level above 1, as a fraction of base:
    --   value(L) = base * (1 + per * (L - 1))
    perLevel = { hp = 0.12, att = 0.05, infamy = 0.15 },
    attMultCap    = 4.0,   -- acc/eva outrun L99 gear past this (Voidspire lesson)
    infamyMultCap = 5.0,   -- parity with the weekly Mythic jackpot

    -- Key delta on a clear, by fraction of the time limit USED.
    -- Walked in order; first match wins; falls through to +1.
    upgrade =
    {
        { frac = 0.40, delta = 3 },   -- blazing: 60%+ of the clock left
        { frac = 0.60, delta = 2 },   -- fast:    40%+ left
        { frac = 1.00, delta = 1 },   -- any clear
    },
    depleteOnFail = 1,
    minLevel      = 1,
    pbBonusMult   = 2.0,   -- one-time Infamy bonus on a new best: infamyBase * this

    -- Weekly affix sets, rotating by ISO week. Every id must exist in
    -- catalog.affixes or catalog.mythicAffixes. ORDER MATTERS: slot 1
    -- is active from M+1, slot 2 joins at M+4, slot 3 at M+7 (see
    -- affixThresholds). Session-time affixes that OVERWRITE the limit
    -- (speedy/lengthy) are excluded - inescapable composes correctly.
    rotation =
    {
        { 'tyrannical',  'mighty',    'apex'        },
        { 'unrelenting', 'frenzied',  'titanic'     },
        { 'apex',        'voracious', 'tyrannical'  },
        { 'titanic',     'fortified', 'inescapable' },
        { 'inescapable', 'evasive',   'unrelenting' },
    },
    affixThresholds =
    {
        { level = 1, count = 1 },
        { level = 4, count = 2 },
        { level = 7, count = 3 },
    },

    -- CharVar names (per-dungeon formats take the dungeon id).
    keyLevelCvFmt   = 'Dungeon_KeyLevel_%s',
    keyBestCvFmt    = 'Dungeon_KeyBest_%s',
    keyBestCvGlobal = 'Dungeon_KeyBest',
}

-- ============================================================
-- PHASE 4 - META-PROGRESSION
-- ============================================================
-- Three login hooks layered on top of the existing reward path:
--
-- 1. DAILY FEATURED DUNGEON
--    One dungeon per UTC day gets a flat Infamy bonus. Selection is
--    DETERMINISTIC - no server-variable state, no race conditions:
--    the featured dungeon for any given UTC day is the same for
--    every player on the server. Computed as:
--        day_index = floor(epoch / 86400)
--        featured  = dungeons[(day_index % #dungeons) + 1]
--    Resets at 00:00 UTC each day. Players see a "FEATURED" marker
--    in the dungeon-master menu.
--
-- 2. STREAK BONUS
--    Charvar Dungeon_Streak tracks consecutive non-abort clears.
--    Each successful clear bumps it by 1, capped at streakCap.
--    Each abort/death/timeout resets it to 0. The Infamy bonus on
--    clear is +streakStep per streak point (e.g. 10% per step,
--    capped at 5 = 50% bonus). Visible in the menu and the clear
--    summary so the player can chase the bonus.
--
-- 3. MYTHIC WEEKLY KEY UI (display only - the gating logic already
--    lives in Phase 2). Main menu now shows "Mythic resets in Xd Yh"
--    next to dungeons whose Mythic key has been burned this week.
-- ============================================================
catalog.featuredBonus   = 0.50  -- +50% Infamy when the dungeon is the day's featured one
catalog.streakStep      = 0.10  -- +10% Infamy per streak point
catalog.streakCap       = 5     -- streak maxes here (so cap mult = 1 + 5*0.10 = 1.50x)
catalog.streakCv        = 'Dungeon_Streak'

-- ============================================================
-- PHASE 6 - PARTY / ALLIANCE SUPPORT
-- ============================================================
-- When a player starts a dungeon, party members in the SAME ZONE
-- (typically GM Home) get warped along and share the run. Leader
-- earns full Infamy; each member alive in the dungeon at clear
-- time gets `memberRewardFactor` of that amount.
--
-- Semantics:
--   * No mid-run join. You're in at warp-in, or you're not in at all.
--   * Leader death  -> run ends for everyone (no reward).
--   * Member death  -> ONLY that member warps out (no reward); the
--                     run continues for the leader + remaining members.
--   * Boss kill     -> success for the leader + every member still
--                     alive in the dungeon zone.
--   * Timeout       -> failure for everyone in the zone.
--   * Manual abort  -> leader-only; ends the run for everyone.
--
-- Bonus-objective evaluation runs on SHARED session telemetry - if
-- any one player drops below 50% HP, the whole party loses Untouched.
-- That's intentional: group play should feel cooperative, not "let
-- the tank solo while everyone else watches."
catalog.party =
{
    enabled            = true,
    memberRewardFactor = 0.80,   -- members earn 80% of leader's Infamy (raised from 0.50 to reduce coordination penalty)
    requireSameZone    = true,   -- members must be in the same zone as leader
    maxMembers         = 5,      -- FFXI party caps at 6 (1 leader + 5 members)
}

-- ============================================================
-- PHASE 5 - BONUS OBJECTIVES (skill-expression rewards)
-- ============================================================
-- Evaluated at endDungeon('cleared'). Each objective with a passing
-- `check(sess)` adds its `bonusMult` to the final Infamy formula
-- (additive with featured + streak bonuses, multiplicative with
-- tier x affixes - see the reward chain at the top of endDungeon).
--
-- Objectives are GLOBAL - they apply to every dungeon, every tier.
-- This keeps the system simple to reason about: a player learns the
-- four bonuses once and chases them across all content.
--
-- Each entry:
--   id          stable string id (used in CharVar achievement tags
--               and in the chat-output label)
--   label       short human name shown in the clear banner
--   bonusMult   reward multiplier added (e.g. 0.25 = +25% Infamy)
--   check       function(sess) -> bool - true awards the bonus
--   reason      one-line description shown when the bonus fires
--
-- Telemetry the check functions can read (all live on `sess`):
--   sess.lowestHpPct       int 0-100, lowest sampled HP% during run
--   sess.oobRescues        int, count of OOB patrol triggers
--   sess.totalTrashSpawned int, waypoint mobs the dungeon spawned
--   sess.trashKilled       int, waypoint mobs the player killed
--   sess.startedAt         os.time() epoch the run began
--   sess.timeLimitOverride int, the run's effective time budget
catalog.bonusObjectives =
{
    {
        id        = 'untouched',
        label     = 'Untouched',
        bonusMult = 0.75,
        reason    = 'never dropped below 50% HP',
        check     = function(sess)
            return (sess.lowestHpPct or 100) >= 50
        end,
    },
    {
        id        = 'pathfinder',
        label     = 'Pathfinder',
        bonusMult = 0.10,
        reason    = 'no out-of-bounds rescues',
        check     = function(sess)
            return (sess.oobRescues or 0) == 0
        end,
    },
    {
        id        = 'slayer',
        label     = 'Slayer',
        bonusMult = 0.25,
        reason    = 'killed every trash mob the dungeon spawned',
        check     = function(sess)
            local spawned = sess.totalTrashSpawned or 0
            local killed  = sess.trashKilled or 0
            -- Defensive: zero-trash runs don't earn this (otherwise
            -- a boss-only dungeon would always trigger it for free).
            return spawned > 0 and killed >= spawned
        end,
    },
    {
        id        = 'lightning',
        label     = 'Lightning',
        bonusMult = 0.30,
        reason    = 'cleared in under 25% of the time limit',
        check     = function(sess)
            local elapsed = os.time() - sess.startedAt
            local limit   = sess.timeLimitOverride or 900
            return elapsed <= (limit * 0.25)
        end,
    },
}

-- ============================================================
-- INFAMY VENDOR INVENTORY
-- ============================================================
-- BiS-tier gear that isn't available through the other vendor systems.
-- Costs are in Infamy. Stocked at launch with a starter set the user
-- can grow over time - just append to this list.
--
-- All items use raw item IDs. To find the right ID for any item:
--   1. !lookupitem <NAME>  in-game
--   2. Or query: SELECT itemid, name FROM item_basic WHERE name LIKE 'X'
catalog.vendorItems =
{
    -- WEAPONS - Aeonic / Mythic / Relic+3 tier
    -- NOTE: id 21646 is actually Caliburnus (moved to the Stage-5 Relics block
    -- below); its old mislabeled 'Naegling' entry was removed. id 21621 is
    -- Naegling (a sword) and is now correctly labeled below -- it was previously
    -- mislabeled 'Daybreak' with shield stats. The real Daybreak (22040, a
    -- caster wand) lives in the auto list, so it is not duplicated here.
    { id = 21632, name = 'Aeneas',         cost =  500, stats = { 'Dagger. Best Rudra Storm.', 'Aeonic weapon.' } },
    { id = 21621, name = 'Naegling',       cost =  300, stats = { 'Sword (1-hand). Great Savage Blade.', 'iLvl 119, broad job access.' } },

    -- ----------------------------------------------------------------
    -- STAGE-5 RELIC WEAPONS  (Level 119 III final forms)
    -- Passive stat blocks added via sql/zz_relic_119iii_mods.sql (BG-Wiki
    -- sourced, INSERT IGNORE). Relic Aftermath + relic WS are scripted and
    -- NOT implemented here, so these are strong stat sticks, not full relics.
    -- Varga/Mpu were already statted in item_mods.sql; Caliburnus in
    -- zz_naked_dungeon_fix.sql. Loughnashade is ilvl 0 in item_equipment.
    -- ----------------------------------------------------------------
    { id = 21535, name = 'Varga Purnikawa', cost = 800, stats = { 'Hand-to-Hand relic (Lv.119 III). Spharai.', 'Final form. Full stat block.' } },
    { id = 21590, name = 'Mpu Gandring',    cost = 800, stats = { 'Dagger relic (Lv.119 III). Mandau.', 'Final form. Full stat block.' } },
    { id = 21646, name = 'Caliburnus',      cost = 800, stats = { 'Sword relic (Lv.119 III). Excalibur.', 'DEX/MND+35, Macc, Magic Dmg+263, Refresh+4.' } },
    { id = 21653, name = 'Helheim',         cost = 800, stats = { 'Great Sword relic (Lv.119 III). Ragnarok.', 'STR/VIT+30, Store TP+7, GS/Parry skill+269.' } },
    { id = 21730, name = 'Spalirisos',      cost = 800, stats = { 'Axe relic (Lv.119 III). Guttler.', 'STR/DEX/CHR+35, Crit rate+15%, Acc+35.' } },
    { id = 21785, name = 'Laphria',         cost = 800, stats = { 'Great Axe relic (Lv.119 III). Bravura.', 'STR/VIT+35, Double Atk+10%, GAxe skill+277.' } },
    { id = 21837, name = 'Foenaria',        cost = 800, stats = { 'Scythe relic (Lv.119 III). Apocalypse.', 'STR/INT+35, Triple Atk+6%, Acc+35.' } },
    { id = 21891, name = 'Gae Buide',       cost = 800, stats = { 'Polearm relic (Lv.119 III). Gungnir.', 'STR/VIT+35, Double Atk+10%, Acc+35.' } },
    { id = 21932, name = 'Dokoku',          cost = 800, stats = { 'Katana relic (Lv.119 III). Kikoku.', 'DEX/AGI+35, Store TP+10, Magic Dmg+263.' } },
    { id = 21986, name = 'Kusanagi',        cost = 800, stats = { 'Great Katana relic (Lv.119 III). Amanomurakumo.', 'STR/DEX+35, Double Atk+10%, GKat skill+277.' } },
    { id = 22002, name = 'Lorg Mor',        cost = 800, stats = { 'Club relic (Lv.119 III). Mjollnir.', 'STR/MND+30, MAtk+50, Magic Dmg+248, DT-7%.' } },
    { id = 22106, name = 'Opashoro',        cost = 800, stats = { 'Staff relic (Lv.119 III). Claustrum.', 'INT/MND+35, MAtk+80, Magic Dmg+325.' } },
    { id = 22163, name = 'Pinaka',          cost = 800, stats = { 'Bow relic (Lv.119 III). Yoichinoyumi.', 'STR/AGI+35, Store TP+10, Archery skill+277.' } },
    { id = 22164, name = 'Earp',            cost = 800, stats = { 'Gun relic (Lv.119 III). Annihilator.', 'DEX/AGI+35, Crit rate+15%, Mkmanship skill+277.' } },
    { id = 26495, name = 'Duban',           cost = 800, stats = { 'Shield relic (Lv.119 III). Aegis.', 'DEF+150, VIT/MND+30, Shield skill+129.' } },
    { id = 22307, name = 'Loughnashade',    cost = 800, stats = { 'Horn relic (Lv.119 III). Gjallarhorn.', 'CHR+20, All Songs+4. (BRD; ilvl 0)' } },

    -- ----------------------------------------------------------------
    -- REQUESTED ENDGAME GEAR  (added on request)
    -- Naked/under-statted pieces are statted in sql/zz_infamy_extra_mods.sql
    -- (Peltast's +3, Pteroslaver Brais +4, Flamma Gambieras +2, Vim Torque +1,
    -- Brigantia's Mantle, + Sroda audit-fix, + the Hjarrandi set below).
    -- Vim Torque +1's "Regain+20 while weapon drawn" is a latent in
    -- sql/zz_infamy_extra_latents.sql. Brigantia's All-Jumps DA+20% and Wyvern
    -- Breath+15 are real engine mods (JUMP_DOUBLE_ATTACK 888 / WYVERN_BREATH 402).
    -- Hjarrandi Helm/Breastplate live in the fixed 'Hjarrandi Tank' set below.
    -- ----------------------------------------------------------------
    -- Armor
    { id = 23500, name = "Peltast's Plackart +3", cost = 400, stats = { 'Body. RUN Relic +3 reforged.', 'Tank/hybrid stat block.' } },
    { id = 23567, name = "Peltast's Vambraces +3",cost = 400, stats = { 'Hands. RUN Relic +3 reforged.', 'Tank/hybrid stat block.' } },
    -- Pteroslaver Brais +4 (24066) is ALREADY sold via the +4 reforge browser
    -- (catalog.plus4Sets, DRG) -- not re-listed here to avoid a duplicate. Its
    -- stats are still fixed by sql/zz_infamy_extra_mods.sql (same item id).
    { id = 25953, name = 'Flamma Gambieras +2',  cost = 400, stats = { 'Feet. Ambuscade.', 'DA+6, Store TP+6, Haste+2%.' } },
    -- Accessories
    { id = 22212, name = 'Utu Grip',             cost = 300, stats = { 'Grip (sub). Acc/Atk + skill.', 'DD grip.' } },
    { id = 21431, name = 'Coiste Bodhar',        cost = 300, stats = { 'Earring. Double Attack + WS damage.', 'Top DD earring (Omen).' } },
    { id = 26022, name = 'Vim Torque +1',        cost = 300, stats = { 'Neck. DEF+15.', 'Regain+20 while weapon drawn (latent).' } },
    { id = 26118, name = 'Sroda Earring',        cost = 300, stats = { 'Earring. STR + WS damage.', 'DD earring.' } },
    { id = 26084, name = 'Sherida Earring',      cost = 300, stats = { 'Earring. DEX, Double Attack, crit.', 'DD earring.' } },
    { id = 26185, name = 'Niqmaddu Ring',        cost = 300, stats = { 'Ring. STR/VIT, Double Attack.', 'DD ring.' } },
    { id = 26190, name = 'Moonlight Ring',       cost = 300, stats = { 'Ring. Hybrid (DT-, Accuracy).', 'Universal ring.' } },
    { id = 26334, name = 'Ioskeha Belt +1',      cost = 300, stats = { 'Waist. DEX + Double Attack.', 'DD belt.' } },
    { id = 26259, name = "Brigantia's Mantle",   cost = 300, stats = { 'Back. DRG cape. DEF+18.', 'All Jumps: DA+20%. Wyvern: Breath+15.' } },

    -- ACCESSORIES - endgame neck/ring/back
    { id = 27928, name = 'Stikini Ring +1',cost =  200, stats = { 'INT+10, MND+10, MEVA+12.', 'Mage ring.' } },

    -- META - the truly exclusive "I'm done" prestige slot
    { id = 13566, name = 'Defending Ring', cost = 1500, stats = { 'Damage Taken -10%.', 'Locks itself once equipped.', 'The grand prize.' } },

    -- ----------------------------------------------------------------
    -- ORPHAN BiS GEAR - no other acquisition path on this server.
    -- These EX/RARE pieces are excluded by the auto-gen scorers
    -- (single-job / non-il119 / +1/+2 NM / REM weapons) and exist
    -- nowhere else (no drop/synth/AH/guild/NPC/quest/event/sparks),
    -- so the Infamy Vendor is their home. Cost scales with ranking.
    -- (Surfaced by an inventory-obtainability audit, 2026-05.)
    -- ----------------------------------------------------------------

    -- REM-tier weapons
    { id = 19832, name = 'Ryunohige',           cost =  800, stats = { 'Polearm (main). Mythic-tier, DRG.', 'EX/RARE. Aftermath weapon.' } },
    { id = 16199, name = 'Ochain',              cost =  800, stats = { 'Grip/shield (sub). Best PLD shield.', 'EX/RARE. High block rate / PDT.' } },
    { id = 21602, name = 'Onion Sword III',     cost =  300, stats = { 'Sword (main or sub), il119.', 'EX/RARE novelty blade.' } },

    -- il119 armor (premium / +2)
    { id = 23734, name = 'Malignance Gloves',   cost =  500, stats = { 'Hands, il119. DD/hybrid (DEX, Acc, M.Acc).', 'EX/RARE. Top-tier gloves.' } },
    { id = 25578, name = 'Jhakri Coronal +2',   cost =  500, stats = { 'Head, il119. Mage (M.Atk / M.Acc).', 'EX/RARE. Reforged Jhakri +2.' } },
    { id = 25794, name = 'Jhakri Robe +2',      cost =  500, stats = { 'Body, il119. Mage (M.Atk / M.Acc).', 'EX/RARE. Reforged Jhakri +2.' } },

    -- il119 armor (base / +1)
    { id = 25603, name = 'Jumalik Helm',        cost =  400, stats = { 'Head, il119. Hybrid (HP, Refresh, MDB).', 'EX. Augmentable.' } },
    { id = 28330, name = 'Founders Greaves',    cost =  400, stats = { 'Feet, il119.', 'EX. Endgame greaves.' } },
    { id = 25809, name = 'Jhakri Cuffs +1',     cost =  400, stats = { 'Hands, il119. Mage (M.Atk / M.Acc).', 'EX/RARE. Reforged Jhakri +1.' } },
    { id = 25868, name = 'Jhakri Slops +1',     cost =  400, stats = { 'Legs, il119. Mage (M.Atk / M.Acc).', 'EX/RARE. Reforged Jhakri +1.' } },
    { id = 25934, name = 'Jhakri Pigaches +1',  cost =  400, stats = { 'Feet, il119. Mage (M.Atk / M.Acc).', 'EX/RARE. Reforged Jhakri +1.' } },

    -- Accessories (neck / waist / back)
    { id = 11007, name = 'Letalis Mantle',      cost =  300, stats = { 'Back. DD cape (STR, Double Attack).', 'EX/RARE.' } },
    { id = 26015, name = 'Combatants Torque',   cost =  300, stats = { 'Neck. DD (Accuracy / Attack).', 'EX/RARE.' } },
    { id = 26003, name = 'Baetyl Pendant',      cost =  300, stats = { 'Neck. Caster (Magic Attack).', 'EX/RARE.' } },
    { id = 27595, name = 'Argochampsa Mantle',  cost =  300, stats = { 'Back. Caster cape (Magic Acc / Atk).', 'EX/RARE.' } },
    { id = 28420, name = 'Fotia Belt',          cost =  250, stats = { 'Waist. Universal WS belt (WS damage).', 'EX/RARE.' } },
    { id = 27510, name = 'Fotia Gorget',        cost =  250, stats = { 'Neck. Universal WS gorget (WS damage).', 'EX/RARE.' } },

    -- WS-focused additions (owner request 2026-06-08)
    { id = 22281, name = 'Knobkierrie',         cost =  250, stats = { 'Ammo. Best WS ammo (Attack+23, WS damage +6%).', 'EX/RARE.' } },
    { id = 26227, name = 'Cornelia\'s Ring',     cost =  500, stats = { 'Ring. Best WS-damage ring (WS damage +10%, WS Acc+20).', 'EX/RARE.' } },
}

-- ============================================================
-- CURATED SETS  (browsed via the "Curated Sets" vendor menu)
-- ============================================================
-- Full armor sets broken out piece-by-piece. Players can buy
-- whichever slots they still need without purchasing duplicates.
-- Each entry:  set (display name), desc (shown in root), pieces[]
-- Each piece:  id, name, cost, stats[]
-- To add a new set, append an entry and restart the server.
-- ============================================================
catalog.vendorSets =
{
    -- NYAME - Su5 universal armor (all 22 jobs). Stats from item_mods.
    {
        set  = 'Nyame Universal',
        desc = 'Su5 armor - wearable by all 22 jobs',
        pieces =
        {
            { id = 23761, name = 'Nyame Helm',      cost =  400, stats = { 'DEF:156 HP+91 STR+26 DEX+25 VIT+24 Acc+30 Atk+30 MAcc+40 MAtk+40 MDB+5', 'Magic Dmg+123, Spell Interrupt-700, Phys Dmg Taken-7%', 'Su5 / all 22 jobs' } },
            { id = 23768, name = 'Nyame Mail',      cost =  800, stats = { 'DEF:189 HP+136 STR+35 DEX+24 VIT+35 Acc+30 Atk+30 MAcc+40 MAtk+40 MDB+8', 'Magic Dmg+139, Spell Interrupt-900, Phys Dmg Taken-9%', 'Su5 / all 22 jobs' } },
            { id = 23775, name = 'Nyame Gauntlets', cost =  400, stats = { 'DEF:142 HP+91 STR+17 DEX+42 VIT+39 Acc+30 Atk+30 MAcc+40 MAtk+40 MDB+4', 'Magic Dmg+112, Spell Interrupt-700, Phys Dmg Taken-7%', 'Su5 / all 22 jobs' } },
            { id = 23782, name = 'Nyame Flanchard', cost =  400, stats = { 'DEF:169 HP+114 STR+43 VIT+30 AGI+34 Acc+30 Atk+30 MAcc+40 MAtk+40 MDB+6', 'Magic Dmg+150, Spell Interrupt-800, Phys Dmg Taken-8%', 'Su5 / all 22 jobs' } },
            { id = 23789, name = 'Nyame Sollerets', cost =  400, stats = { 'DEF:122 HP+68 STR+23 DEX+26 AGI+38 Acc+30 Atk+30 MAcc+40 MAtk+40 MDB+5', 'Magic Dmg+150, Spell Interrupt-700, Phys Dmg Taken-7%', 'Su5 / all 22 jobs' } },
        },
    },

    -- HJARRANDI - Odyssey-augmented tank/DPS armor (head + body only)
    {
        set  = 'Hjarrandi Tank',
        desc = 'Odyssey-augmented tank/DPS armor',
        pieces =
        {
            { id = 25592, name = 'Hjarrandi Helm',        cost =  400, stats = { 'Tank/DD head. DA+6, Store TP+7, DT-10%.', 'Reforged Hjarrandi (fixed from 27637=evalach).' } },
            { id = 25766, name = 'Hjarrandi Breastplate', cost =  800, stats = { 'Tank/DD body. Store TP+10, Crit+13%, DT-12%.', 'Reforged Hjarrandi (fixed from 27718=worm_masque).' } },
        },
    },
}

-- DOCGEN:INFAMY_AUTO:BEGIN
-- catalog.vendorItemsAuto
--
-- AUTO-GENERATED by tools/build_infamy_top_picks.py — do NOT
-- hand-edit. To refresh after re-scoring any gear catalog:
--     python tools/build_infamy_top_picks.py
-- Or run tools/rebalance_all.bat to re-rank every catalog AND
-- this auto-promoted Infamy Vendor list in one shot.
--
-- Sourced from the catalog.infamy tier of each scored catalog:
--   * Armor / Weapons: top 5 per slot / weapon category (the
--     'best options in game', skimmed out of the gold gear vendor).
--   * Accessory: the 22 Sortie JSE +2 earrings (Infamy exclusive).
-- The hand-curated catalog.vendorItems list above is left untouched.
-- 103 gear + 22 Sortie earrings = 125 items.
catalog.vendorItemsAuto =
{
    { id =  20672, name = 'Ice Brand'                         , cost =  800, stats = { 'CASTER score 1060', 'Weapons top-5 (Swords)', 'Jobs: RDM/PLD/BLU' } },
    { id =  22042, name = 'Wizards Rod'                       , cost =  800, stats = { 'CASTER score 1060', 'Weapons top-5 (Clubs)', 'Jobs: BLM/RDM/SCH/GEO' } },
    { id =  22055, name = 'Oranyan'                           , cost =  800, stats = { 'CASTER score 1054', 'Weapons top-5 (Staves)', 'Jobs: WHM/BLM/RDM/BRD/SMN/SCH/GEO' } },
    { id =  22040, name = 'Daybreak'                          , cost =  800, stats = { 'CASTER score 1033', 'Weapons top-5 (Clubs)', 'Jobs: WHM/BLM/RDM/BRD/SMN/SCH/GEO' } },
    { id =  22081, name = 'Raetic Staff +1'                   , cost =  800, stats = { 'CASTER score 1019', 'Weapons top-5 (Staves)', 'Jobs: WAR/MNK/WHM/BLM/RDM/BST/BRD/SMN/SCH/GEO' } },
    { id =  22086, name = 'Xoanon'                            , cost =  800, stats = { 'CASTER score 1018', 'Weapons top-5 (Staves)', 'Jobs: WAR/MNK/WHM/BLM/RDM/BST/BRD/SMN/SCH/GEO' } },
    { id =  21071, name = 'Cath Palug Hammer'                 , cost =  800, stats = { 'CASTER score 1013', 'Weapons top-5 (Clubs)', 'Jobs: WHM/GEO' } },
    { id =  22058, name = 'Contemplator +1'                   , cost =  800, stats = { 'CASTER score 1004', 'Weapons top-5 (Staves)', 'Jobs: WHM/BLM/RDM/BRD/SMN/SCH/GEO' } },
    { id =  21830, name = 'Drepanum'                          , cost =  800, stats = { 'CASTER score 1003', 'Weapons top-5 (Scythes)', 'Jobs: WAR/BLM/DRK/BST' } },
    { id =  22031, name = 'Maxentius'                         , cost =  800, stats = { 'CASTER score 988', 'Weapons top-5 (Clubs)', 'Jobs: WHM/BLM/RDM/SMN/BLU/SCH/GEO' } },
    { id =  21637, name = 'Sakpatas Sword'                    , cost =  800, stats = { 'CASTER score 977', 'Weapons top-5 (Swords)', 'Jobs: RDM/PLD/BLU' } },
    { id =  21565, name = 'Tauret'                            , cost =  800, stats = { 'CASTER score 973', 'Weapons top-5 (Daggers)', 'Jobs: RDM/THF/BST/BRD/RNG/NIN/COR/PUP/DNC' } },
    { id =  21829, name = 'Kaja Scythe'                       , cost =  800, stats = { 'CASTER score 969', 'Weapons top-5 (Scythes)', 'Jobs: WAR/BLM/DRK/BST' } },
    { id =  21564, name = 'Kaja Knife'                        , cost =  800, stats = { 'CASTER score 939', 'Weapons top-5 (Daggers)', 'Jobs: RDM/THF/BST/BRD/RNG/NIN/COR/PUP/DNC' } },
    { id =  21620, name = 'Kaja Sword'                        , cost =  800, stats = { 'CASTER score 939', 'Weapons top-5 (Swords)', 'Jobs: WAR/RDM/THF/PLD/DRK/BST/BRD/RNG/NIN/DRG/BLU/COR/RUN' } },
    { id =  21563, name = 'Eletta Knife'                      , cost =  800, stats = { 'CASTER score 890', 'Weapons top-5 (Daggers)', 'Jobs: RDM/THF/BST/BRD/RNG/NIN/COR/PUP/DNC' } },
    { id =  21828, name = 'Eletta Scythe'                     , cost =  800, stats = { 'CASTER score 890', 'Weapons top-5 (Scythes)', 'Jobs: WAR/BLM/DRK/BST' } },
    { id =  26963, name = 'Onca Suit'                         , cost =  800, stats = { 'DPS score 881', 'Armor top-5 (body)', 'Jobs: WAR/MNK/WHM/BLM/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/SMN/BLU/COR/PUP/DNC/SCH/GEO/RUN' } },
    { id =  23716, name = 'Volte Haubert'                     , cost =  800, stats = { 'TANK score 562', 'Armor top-5 (body)', 'Jobs: WAR/PLD/DRK' } },
    { id =  25799, name = 'Mallquis Saio +2'                  , cost =  800, stats = { 'CASTER score 537', 'Armor top-5 (body)', 'Jobs: BLM/SCH/GEO' } },
    { id =  23765, name = 'Mpacas Doublet'                    , cost =  800, stats = { 'TANK score 509', 'Armor top-5 (body)', 'Jobs: MNK/SAM/NIN/PUP' } },
    { id =  23764, name = 'Sakpatas Breastplate'              , cost =  500, stats = { 'TANK score 501', 'Armor top-5 (body)', 'Jobs: WAR/PLD/DRK' } },
    { id =  25888, name = 'Mallquis Trews +2'                 , cost =  500, stats = { 'CASTER score 499', 'Armor top-5 (legs)', 'Jobs: BLM/SCH/GEO' } },
    { id =  23781, name = 'Bunzis Pants'                      , cost =  500, stats = { 'CASTER score 469', 'Armor top-5 (legs)', 'Jobs: WHM/RDM/BRD/SMN' } },
    { id =  23779, name = 'Mpacas Hose'                       , cost =  500, stats = { 'TANK score 447', 'Armor top-5 (legs)', 'Jobs: MNK/SAM/NIN/PUP' } },
    { id =  25571, name = 'Mallquis Chapeau +2'               , cost =  500, stats = { 'CASTER score 445', 'Armor top-5 (head)', 'Jobs: BLM/SCH/GEO' } },
    { id =  25837, name = 'Mallquis Cuffs +2'                 , cost =  500, stats = { 'CASTER score 445', 'Armor top-5 (hands)', 'Jobs: BLM/SCH/GEO' } },
    { id =  23724, name = 'Volte Brayettes'                   , cost =  500, stats = { 'TANK score 440', 'Armor top-5 (legs)', 'Jobs: WAR/PLD/DRK' } },
    { id =  23778, name = 'Sakpatas Cuisses'                  , cost =  500, stats = { 'TANK score 439', 'Armor top-5 (legs)', 'Jobs: WAR/PLD/DRK' } },
    { id =  23774, name = 'Bunzis Gloves'                     , cost =  500, stats = { 'CASTER score 432', 'Armor top-5 (hands)', 'Jobs: WHM/RDM/BRD/SMN' } },
    { id =  23760, name = 'Bunzis Hat'                        , cost =  500, stats = { 'CASTER score 413', 'Armor top-5 (head)', 'Jobs: WHM/RDM/BRD/SMN' } },
    { id =  25955, name = 'Mallquis Clogs +2'                 , cost =  500, stats = { 'CASTER score 411', 'Armor top-5 (feet)', 'Jobs: BLM/SCH/GEO' } },
    { id =  23788, name = 'Bunzis Sabots'                     , cost =  500, stats = { 'CASTER score 407', 'Armor top-5 (feet)', 'Jobs: WHM/RDM/BRD/SMN' } },
    { id =  23757, name = 'Sakpatas Helm'                     , cost =  500, stats = { 'TANK score 405', 'Armor top-5 (head)', 'Jobs: WAR/PLD/DRK' } },
    { id =  23772, name = 'Mpacas Gloves'                     , cost =  500, stats = { 'TANK score 402', 'Armor top-5 (hands)', 'Jobs: MNK/SAM/NIN/PUP' } },
    { id =  23771, name = 'Sakpatas Gauntlets'                , cost =  500, stats = { 'TANK score 398', 'Armor top-5 (hands)', 'Jobs: WAR/PLD/DRK' } },
    { id =  23758, name = 'Mpacas Cap'                        , cost =  500, stats = { 'TANK score 391', 'Armor top-5 (head)', 'Jobs: MNK/SAM/NIN/PUP' } },
    { id =  23712, name = 'Volte Salade'                      , cost =  500, stats = { 'TANK score 389', 'Armor top-5 (head)', 'Jobs: WAR/PLD/DRK' } },
    { id =  23773, name = 'Agwus Gages'                       , cost =  500, stats = { 'CASTER score 387', 'Armor top-5 (hands)', 'Jobs: BLM/SCH/GEO/RUN' } },
    { id =  21779, name = 'Lycurgos'                          , cost =  500, stats = { 'WS score 364', 'Weapons top-5 (Great Axes)', 'Jobs: WAR/DRK/RUN' } },
    { id =  23787, name = 'Agwus Pigaches'                    , cost =  500, stats = { 'CASTER score 361', 'Armor top-5 (feet)', 'Jobs: BLM/SCH/GEO/RUN' } },
    { id =  23785, name = 'Sakpatas Leggings'                 , cost =  500, stats = { 'TANK score 359', 'Armor top-5 (feet)', 'Jobs: WAR/PLD/DRK' } },
    { id =  23786, name = 'Mpacas Boots'                      , cost =  500, stats = { 'TANK score 358', 'Armor top-5 (feet)', 'Jobs: MNK/SAM/NIN/PUP' } },
    { id =  22114, name = 'Steinthor'                         , cost =  500, stats = { 'WS score 346', 'Weapons top-5 (Archery)', 'Jobs: RNG' } },
    { id =  21975, name = 'Hachimonji'                        , cost =  500, stats = { 'WS score 344', 'Weapons top-5 (Great Katana)', 'Jobs: SAM/NIN' } },
    { id =  21221, name = 'Brahmastra'                        , cost =  500, stats = { 'WS score 326', 'Weapons top-5 (Archery)', 'Jobs: RNG' } },
    { id =  22113, name = 'Teller'                            , cost =  500, stats = { 'WS score 322', 'Weapons top-5 (Archery)', 'Jobs: RNG' } },
    { id =  21778, name = 'Kaja Chopper'                      , cost =  500, stats = { 'WS score 319', 'Weapons top-5 (Great Axes)', 'Jobs: WAR/DRK/RUN' } },
    { id =  21674, name = 'Nandaka'                           , cost =  500, stats = { 'WS score 312', 'Weapons top-5 (Great Swords)', 'Jobs: WAR/PLD/DRK/RUN' } },
    { id =  21883, name = 'Shining One'                       , cost =  500, stats = { 'WS score 312', 'Weapons top-5 (Polearms)', 'Jobs: WAR/PLD/SAM/DRG' } },
    { id =  22121, name = 'Imati +1'                          , cost =  500, stats = { 'WS score 307', 'Weapons top-5 (Marksmanship)', 'Jobs: RNG' } },
    { id =  21567, name = 'Gletis Knife'                      , cost =  500, stats = { 'DPS score 300', 'Weapons top-5 (Daggers)', 'Jobs: RDM/THF/BRD/RNG/NIN/COR/DNC' } },
    { id =  21974, name = 'Kaja Tachi'                        , cost =  350, stats = { 'WS score 300', 'Weapons top-5 (Great Katana)', 'Jobs: SAM/NIN' } },
    { id =  21683, name = 'Ragnarok 119 Iii'                  , cost =  350, stats = { 'WS score 296', 'Weapons top-5 (Great Swords)', 'Jobs: WAR/PLD/DRK' } },
    { id =  22123, name = 'Arasy Bow +1'                      , cost =  350, stats = { 'WS score 295', 'Weapons top-5 (Archery)', 'Jobs: RNG' } },
    { id =  21964, name = 'Beryllium Tachi +1'                , cost =  350, stats = { 'WS score 286', 'Weapons top-5 (Great Katana)', 'Jobs: SAM/NIN' } },
    { id =  21870, name = 'Exalted Spear +1'                  , cost =  350, stats = { 'WS score 278', 'Weapons top-5 (Polearms)', 'Jobs: WAR/PLD/SAM/DRG' } },
    { id =  21673, name = 'Kaja Claymore'                     , cost =  350, stats = { 'WS score 276', 'Weapons top-5 (Great Swords)', 'Jobs: WAR/PLD/DRK/RUN' } },
    { id =  21882, name = 'Kaja Lance'                        , cost =  350, stats = { 'WS score 276', 'Weapons top-5 (Polearms)', 'Jobs: WAR/PLD/SAM/DRG' } },
    { id =  21519, name = 'Karambit'                          , cost =  350, stats = { 'WS score 275', 'Weapons top-5 (H2H)', 'Jobs: WAR/MNK/RDM/THF/DRK/BST/NIN/PUP/DNC' } },
    { id =  21766, name = 'Hepatizon Axe +1'                  , cost =  350, stats = { 'WS score 273', 'Weapons top-5 (Great Axes)', 'Jobs: WAR/DRK/RUN' } },
    { id =  21816, name = 'Maliya Sickle +1'                  , cost =  350, stats = { 'WS score 272', 'Weapons top-5 (Scythes)', 'Jobs: WAR/BLM/DRK/BST' } },
    { id =  21220, name = 'Paloma Bow +1'                     , cost =  350, stats = { 'WS score 272', 'Weapons top-5 (Archery)', 'Jobs: RNG' } },
    { id =  21819, name = 'Raetic Scythe +1'                  , cost =  350, stats = { 'WS score 270', 'Weapons top-5 (Scythes)', 'Jobs: WAR/BLM/DRK/BST' } },
    { id =  21485, name = 'Fomalhaut'                         , cost =  350, stats = { 'WS score 270', 'Weapons top-5 (Marksmanship)', 'Jobs: RNG/COR' } },
    { id =  21527, name = 'Sakpatas Fists'                    , cost =  350, stats = { 'WS score 262', 'Weapons top-5 (H2H)', 'Jobs: MNK/PUP' } },
    { id =  21768, name = 'Raetic Chopper +1'                 , cost =  350, stats = { 'WS score 262', 'Weapons top-5 (Great Axes)', 'Jobs: WAR/BLM/DRK/BRD/SMN/SCH/RUN' } },
    { id =  21663, name = 'Raetic Algol +1'                   , cost =  350, stats = { 'WS score 256', 'Weapons top-5 (Great Swords)', 'Jobs: WAR/PLD/DRK/RUN' } },
    { id =  26023, name = 'Sanctity Necklace'                 , cost =  350, stats = { 'CASTER score 252', 'Accessory top-5 (neck)', 'Jobs: All' } },
    { id =  22136, name = 'Arasy Gun +1'                      , cost =  350, stats = { 'WS score 252', 'Weapons top-5 (Marksmanship)', 'Jobs: RNG/COR' } },
    { id =  21707, name = 'Barbarity +1'                      , cost =  350, stats = { 'WS score 250', 'Weapons top-5 (Axes)', 'Jobs: WAR/BST' } },
    { id =  21722, name = 'Dolichenus'                        , cost =  350, stats = { 'WS score 235', 'Weapons top-5 (Axes)', 'Jobs: WAR/DRK/BST/RNG/RUN' } },
    { id =  21777, name = 'Eletta Chopper'                    , cost =  350, stats = { 'WS score 234', 'Weapons top-5 (Great Axes)', 'Jobs: WAR/DRK/RUN' } },
    { id =  21518, name = 'Kaja Knuckles'                     , cost =  350, stats = { 'WS score 232', 'Weapons top-5 (H2H)', 'Jobs: WAR/MNK/RDM/THF/DRK/BST/NIN/PUP/DNC' } },
    { id =  21872, name = 'Raetic Halberd +1'                 , cost =  350, stats = { 'WS score 226', 'Weapons top-5 (Polearms)', 'Jobs: WAR/BLM/PLD/BRD/SAM/DRG/SMN/SCH' } },
    { id =  21881, name = 'Eletta Lance'                      , cost =  350, stats = { 'WS score 222', 'Weapons top-5 (Polearms)', 'Jobs: WAR/PLD/SAM/DRG' } },
    { id =  19209, name = 'Molybdosis'                        , cost =  350, stats = { 'WS score 222', 'Weapons top-5 (Marksmanship)', 'Jobs: COR' } },
    { id =  21973, name = 'Eletta Tachi'                      , cost =  350, stats = { 'WS score 216', 'Weapons top-5 (Great Katana)', 'Jobs: SAM/NIN' } },
    { id =  21528, name = 'Dragon Fangs'                      , cost =  350, stats = { 'WS score 214', 'Weapons top-5 (H2H)', 'Jobs: MNK/PUP' } },
    { id =  21721, name = 'Kaja Axe'                          , cost =  350, stats = { 'WS score 204', 'Weapons top-5 (Axes)', 'Jobs: WAR/DRK/BST/RNG/RUN' } },
    { id =  21709, name = 'Beryllium Pick +1'                 , cost =  350, stats = { 'WS score 180', 'Weapons top-5 (Axes)', 'Jobs: WAR/DRK/BST/RUN' } },
    { id =  27620, name = 'Aurists Cape +1'                   , cost =  350, stats = { 'CASTER score 177', 'Accessory top-5 (back)', 'Jobs: WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO' } },
    { id =  26357, name = 'Skrymir Cord +1'                   , cost =  350, stats = { 'CASTER score 175', 'Accessory top-5 (waist)', 'Jobs: All' } },
    { id =  26269, name = 'Moonlight Cape'                    , cost =  250, stats = { 'TANK score 171', 'Accessory top-5 (back)', 'Jobs: All' } },
    { id =  21752, name = 'Farsha'                            , cost =  250, stats = { 'WS score 168', 'Weapons top-5 (Axes)', 'Jobs: WAR/BST' } },
    { id =  26341, name = 'Moonbow Belt +1'                   , cost =  250, stats = { 'DPS score 162', 'Accessory top-5 (waist)', 'Jobs: MNK/PUP' } },
    { id =  21972, name = 'Ajja Tachi'                        , cost =  250, stats = { 'WS score 161', 'Weapons top-5 (Great Katana)', 'Jobs: SAM/NIN' } },
    { id =  27615, name = 'Reiki Cloak'                       , cost =  250, stats = { 'TANK score 153', 'Accessory top-5 (back)', 'Jobs: WAR/MNK/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' } },
    { id =  26004, name = 'Lissome Necklace'                  , cost =  250, stats = { 'DPS score 140', 'Accessory top-5 (neck)', 'Jobs: All' } },
    { id =  26361, name = 'Gerdr Belt +1'                     , cost =  250, stats = { 'DPS score 136', 'Accessory top-5 (waist)', 'Jobs: WAR/MNK/RDM/THF/PLD/DRK/BST/BRD/SAM/NIN/DRG/BLU/COR/DNC/RUN' } },
    { id =  13655, name = 'Sand Mantle'                       , cost =  250, stats = { 'TANK score 108', 'Accessory top-5 (back)', 'Jobs: WAR/MNK/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' } },
    { id =  11607, name = 'Artemiss Medal'                    , cost =  250, stats = { 'CASTER score 95', 'Accessory top-5 (neck)', 'Jobs: All' } },
    { id =  26359, name = 'Orpheuss Sash'                     , cost =  250, stats = { 'DPS score 92', 'Accessory top-5 (waist)', 'Jobs: All' } },
    { id =  25461, name = 'Abyssal Bead Necklace +2'          , cost =  250, stats = { 'WS score 90', 'Accessory top-5 (neck)', 'Jobs: DRK' } },
    { id =  26191, name = 'Regal Ring'                        , cost =  250, stats = { 'WS score 85', 'Accessory top-5 (ring)', 'Jobs: WAR/MNK/THF/PLD/DRK/BST/RNG/SAM/NIN/DRG/COR/PUP/DNC/RUN' } },
    { id =  25497, name = 'Dragoons Collar +2'                , cost =  250, stats = { 'WS score 83', 'Accessory top-5 (neck)', 'Jobs: DRG' } },
    { id =  28607, name = 'Aput Mantle +1'                    , cost =  250, stats = { 'CASTER score 80', 'Accessory top-5 (back)', 'Jobs: WAR/MNK/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' } },
    { id =  26088, name = 'Malignance Earring'                , cost =  250, stats = { 'CASTER score 76', 'Accessory top-5 (ear)', 'Jobs: WHM/BLM/RDM/DRK/SMN/SCH/GEO' } },
    { id =  28471, name = 'Gere Ring'                         , cost =  250, stats = { 'DPS score 76', 'Accessory top-5 (ring)', 'Jobs: MNK/THF/BST/NIN/PUP/DNC' } },
    { id =  26186, name = 'Ilabrat Ring'                      , cost =  250, stats = { 'WS score 72', 'Accessory top-5 (ring)', 'Jobs: MNK/WHM/RDM/THF/BST/BRD/RNG/SAM/NIN/BLU/COR/DNC/RUN' } },
    { id =  25439, name = 'Wicce Earring +1'                  , cost =  250, stats = { 'CASTER score 56', 'Accessory top-5 (ear)', 'Jobs: BLM' } },
    { id =  25535, name = 'Arbatel Earring +1'                , cost =  250, stats = { 'CASTER score 56', 'Accessory top-5 (ear)', 'Jobs: SCH' } },
    { id =  26108, name = 'Odr Earring'                       , cost =  250, stats = { 'DPS score 55', 'Accessory top-5 (ear)', 'Jobs: MNK/THF/RNG/NIN/BLU/COR/DNC/RUN' } },
    { id =  25422, name = 'Boii Earring +2'                   , cost =  300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for WAR', 'Jobs: WAR' } },
    { id =  25428, name = 'Bhikku Earring +2'                 , cost =  300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for MNK', 'Jobs: MNK' } },
    { id =  25434, name = 'Ebers Earring +2'                  , cost =  300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for WHM', 'Jobs: WHM' } },
    { id =  25440, name = 'Wicce Earring +2'                  , cost =  300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for BLM', 'Jobs: BLM' } },
    { id =  25446, name = 'Lethargy Earring +2'               , cost =  300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for RDM', 'Jobs: RDM' } },
    { id =  25452, name = 'Skulkers Earring +2'               , cost =  300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for THF', 'Jobs: THF' } },
    { id =  25458, name = 'Chevaliers Earring +2'             , cost =  300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for PLD', 'Jobs: PLD' } },
    { id =  25464, name = 'Heathens Earring +2'               , cost =  300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for DRK', 'Jobs: DRK' } },
    { id =  25470, name = 'Nukumi Earring +2'                 , cost =  300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for BST', 'Jobs: BST' } },
    { id =  25476, name = 'Fili Earring +2'                   , cost =  300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for BRD', 'Jobs: BRD' } },
    { id =  25482, name = 'Amini Earring +2'                  , cost =  300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for RNG', 'Jobs: RNG' } },
    { id =  25488, name = 'Kasuga Earring +2'                 , cost =  300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for SAM', 'Jobs: SAM' } },
    { id =  25494, name = 'Hattori Earring +2'                , cost =  300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for NIN', 'Jobs: NIN' } },
    { id =  25500, name = 'Peltasts Earring +2'               , cost =  300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for DRG', 'Jobs: DRG' } },
    { id =  25506, name = 'Beckoners Earring +2'              , cost =  300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for SMN', 'Jobs: SMN' } },
    { id =  25512, name = 'Hashishin Earring +2'              , cost =  300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for BLU', 'Jobs: BLU' } },
    { id =  25518, name = 'Chasseurs Earring +2'              , cost =  300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for COR', 'Jobs: COR' } },
    { id =  25524, name = 'Karagoz Earring +2'                , cost =  300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for PUP', 'Jobs: PUP' } },
    { id =  25530, name = 'Maculele Earring +2'               , cost =  300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for DNC', 'Jobs: DNC' } },
    { id =  25536, name = 'Arbatel Earring +2'                , cost =  300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for SCH', 'Jobs: SCH' } },
    { id =  25542, name = 'Azimuth Earring +2'                , cost =  300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for GEO', 'Jobs: GEO' } },
    { id =  25548, name = 'Erilaz Earring +2'                 , cost =  300, stats = { 'Sortie JSE +2 earring', 'Best-in-slot for RUN', 'Jobs: RUN' } },
}
-- DOCGEN:INFAMY_AUTO:END

-- Page size for the vendor menu (15-byte budget per line, 6 lines fit
-- comfortably on the customMenu cap).
catalog.vendorPageSize = 6

-- ============================================================
-- +4 REFORGE SETS  (separate browser: Job -> Set -> Slot)
-- ============================================================
-- 200 Infamy per piece (1000 per full 5-slot set). Stats sourced from
-- BG-Wiki via tools/build_infamy_plus4_catalog.py - regenerate that
-- script to refresh this section.
catalog.plus4Cost = 200

-- (Auto-generated table follows; do NOT hand-edit. To refresh:
--   python tools/build_infamy_plus4_catalog.py
-- then paste the contents of tools/_plus4_catalog.lua over this block.)
-- AUTO-GENERATED by tools/build_infamy_plus4_catalog.py
-- Source: tools/bgwiki_stats_cache.json
-- Edit the SET_TO_JOB map in the Python script, not this file.

catalog.plus4Sets =
{
    -- BLM
    ['BLM'] = {
        { set = 'Archmages', pieces = {
            ['head'] = { id = 23921, name = 'Archmages Petasos +4', stats = { 'DEF:120 HP+66 MP+62 STR+27 DEX+24 VIT+29 AGI+24 INT+39 MND+29 CHR+29 Accuracy+42 Magic Acc' } },
            ['body'] = { id = 23966, name = 'Archmages Coat +4', stats = { 'DEF:150 HP+84 MP+89 STR+34 DEX+31 VIT+36 AGI+31 INT+51 MND+39 CHR+39 Accuracy+45 Magic Acc' } },
            ['hands'] = { id = 24011, name = 'Archmages Gloves +4', stats = { 'DEF:104 HP+52 MP+44 STR+19 DEX+38 VIT+40 AGI+15 INT+41 MND+43 CHR+29 Accuracy+43 Magic Acc' } },
            ['legs'] = { id = 24056, name = 'Archmages Tonban +4', stats = { 'DEF:128 HP+73 MP+95 STR+38 VIT+27 AGI+27 INT+55 MND+34 CHR+29 Accuracy+44 Magic Accuracy+5' } },
            ['feet'] = { id = 24101, name = 'Archmages Sabots +4', stats = { 'DEF:88 HP+43 MP+44 STR+23 DEX+21 VIT+25 AGI+43 INT+35 MND+29 CHR+44 Accuracy+41 Magic Accu' } },
        } },
        { set = 'Spaekonas', pieces = {
            ['head'] = { id = 23898, name = 'Spaekonas Petasos +4', stats = { 'DEF:118 HP+74 MP+68 STR+29 DEX+32 VIT+29 AGI+34 INT+37 MND+39 CHR+34 Accuracy+57 Magic Acc' } },
            ['body'] = { id = 23943, name = 'Spaekonas Coat +4', stats = { 'DEF:148 HP+101 MP+108 STR+31 DEX+34 VIT+31 AGI+36 INT+39 MND+44 CHR+39 Accuracy+65 Magic A' } },
            ['legs'] = { id = 24033, name = 'Spaekonas Tonban +4', stats = { 'DEF:130 HP+84 MP+168 STR+35 VIT+22 AGI+32 INT+44 MND+39 CHR+29 Accuracy+59 Magic Accuracy+' } },
            ['feet'] = { id = 24078, name = 'Spaekonas Sabots +4', stats = { 'DEF:88 HP+51 MP+53 STR+20 DEX+24 VIT+20 AGI+48 INT+32 MND+34 CHR+44 Accuracy+64 Magic Accu' } },
        } },
    },
    -- BLU
    ['BLU'] = {
        { set = 'Assimilators', pieces = {
            ['head'] = { id = 23910, name = 'Assimilators Keffiyeh +4', stats = { 'DEF:127 HP+89 MP+69 STR+30 DEX+39 VIT+30 AGI+39 INT+33 MND+36 CHR+31 Accuracy+66 Magic Acc' } },
            ['body'] = { id = 23955, name = 'Assimilators Jubbah +4', stats = { 'DEF:157 HP+123 MP+101 STR+39 DEX+49 VIT+34 AGI+43 INT+33 MND+36 CHR+33 Accuracy+60 Magic A' } },
            ['hands'] = { id = 24000, name = 'Assimilators Bazubands +4', stats = { 'DEF:115 HP+57 MP+65 STR+21 DEX+50 VIT+42 AGI+20 INT+32 MND+43 CHR+27 Accuracy+58 Magic Acc' } },
            ['legs'] = { id = 24045, name = 'Assimilators Shalwar +4', stats = { 'DEF:139 HP+113 MP+42 STR+42 VIT+26 AGI+35 INT+43 MND+30 CHR+21 Accuracy+59 Magic Accuracy+' } },
            ['feet'] = { id = 24090, name = 'Assimilators Charuqs +4', stats = { 'DEF:97 HP+69 MP+50 STR+22 DEX+39 VIT+22 AGI+52 MND+25 CHR+40 Accuracy+65 Attack+43 Magic A' } },
        } },
        { set = 'Luhlaza', pieces = {
            ['head'] = { id = 23933, name = 'Luhlaza Keffiyeh +4', stats = { 'DEF:126 HP+101 MP+88 STR+35 DEX+29 VIT+35 AGI+29 INT+33 MND+30 CHR+26 Accuracy+42 Attack+7' } },
            ['body'] = { id = 23978, name = 'Luhlaza Jubbah +4', stats = { 'DEF:160 HP+89 MP+74 STR+42 DEX+42 VIT+39 AGI+38 INT+36 MND+33 CHR+33 Accuracy+55 Attack+96' } },
            ['hands'] = { id = 24023, name = 'Luhlaza Bazubands +4', stats = { 'DEF:114 HP+80 MP+55 STR+26 DEX+49 VIT+47 AGI+15 INT+25 MND+44 CHR+27 Accuracy+49 Attack+73' } },
            ['legs'] = { id = 24068, name = 'Luhlaza Shalwar +4', stats = { 'DEF:138 HP+97 MP+50 STR+46 VIT+31 AGI+32 INT+43 MND+27 CHR+21 Accuracy+50 Magic Accuracy+5' } },
            ['feet'] = { id = 24113, name = 'luhlaza charuqs +4', stats = { 'DEF:98 HP+43 MP+66 STR+27 DEX+34 VIT+27 AGI+47 INT+25 MND+22 CHR+40 Accuracy+41 Attack+96 ' } },
        } },
    },
    -- BRD
    ['BRD'] = {
        { set = 'Bihu', pieces = {
            ['head'] = { id = 23927, name = 'Bihu Roundlet +4', stats = { 'DEF:120 HP+66 MP+62 STR+24 DEX+24 VIT+33 AGI+24 INT+32 MND+27 CHR+42 Accuracy+42 Attack+72' } },
            ['body'] = { id = 23972, name = 'Bihu Justaucorps +4', stats = { 'DEF:150 HP+99 MP+104 STR+42 DEX+41 VIT+44 AGI+41 INT+42 MND+38 CHR+45 Accuracy+58 Attack+1' } },
            ['hands'] = { id = 24017, name = 'Bihu Cuffs +4', stats = { 'DEF:109 HP+52 MP+44 STR+19 DEX+38 VIT+40 AGI+15 INT+32 MND+42 CHR+35 Accuracy+43 Attack+73' } },
            ['legs'] = { id = 24062, name = 'Bihu Cannions +4', stats = { 'DEF:132 HP+113 MP+99 STR+36 VIT+25 AGI+27 INT+57 MND+43 CHR+45 Accuracy+44 Attack+74 Magic' } },
            ['feet'] = { id = 24107, name = 'Bihu Slippers +4', stats = { 'DEF:91 HP+43 MP+44 STR+20 DEX+21 VIT+22 AGI+43 INT+30 MND+27 CHR+50 Accuracy+41 Attack+71 ' } },
        } },
        { set = 'Brioso', pieces = {
            ['head'] = { id = 23904, name = 'Brioso Roundlet +4', stats = { 'DEF:120 HP+74 MP+52 STR+26 DEX+32 VIT+26 AGI+34 INT+34 MND+38 CHR+43 Accuracy+71 Magic Acc' } },
            ['body'] = { id = 23949, name = 'Brioso Justaucorps +4', stats = { 'DEF:150 HP+101 MP+79 STR+29 DEX+34 VIT+29 AGI+36 INT+39 MND+41 CHR+45 Accuracy+74 Magic Ac' } },
            ['hands'] = { id = 23994, name = 'Brioso Cuffs +4', stats = { 'DEF:108 HP+53 MP+34 STR+16 DEX+41 VIT+35 AGI+20 INT+29 MND+45 CHR+41 Accuracy+58 Magic Acc' } },
            ['legs'] = { id = 24039, name = 'Brioso Cannions +4', stats = { 'DEF:132 HP+84 MP+79 STR+33 VIT+20 AGI+32 INT+44 MND+36 CHR+35 Accuracy+66 Magic Accuracy+6' } },
            ['feet'] = { id = 24084, name = 'Brioso Slippers +4', stats = { 'DEF:90 HP+84 MP+64 STR+17 DEX+24 VIT+17 AGI+48 INT+27 MND+30 CHR+50 Accuracy+56 Magic Accu' } },
        } },
    },
    -- BST
    ['BST'] = {
        { set = 'Ankusa', pieces = {
            ['head'] = { id = 23926, name = 'Ankusa Helm +4', stats = { 'DEF:128 HP+66 MP+53 STR+37 DEX+36 VIT+30 AGI+29 INT+28 MND+25 CHR+33 Accuracy+42 Attack+72' } },
            ['body'] = { id = 23971, name = 'Ankusa Jackcoat +4', stats = { 'DEF:153 HP+79 MP+64 STR+38 DEX+43 VIT+34 AGI+38 INT+37 MND+33 CHR+33 Accuracy+40 Attack+65' } },
            ['hands'] = { id = 24016, name = 'Ankusa Gloves +4', stats = { 'DEF:116 HP+55 STR+26 DEX+45 VIT+47 AGI+22 INT+25 MND+40 CHR+27 Accuracy+43 Attack+73 Magic' } },
            ['legs'] = { id = 24061, name = 'Ankusa Trousers +4', stats = { 'DEF:137 HP+77 STR+44 DEX+20 VIT+31 AGI+30 INT+43 MND+27 CHR+21 Accuracy+44 Attack+74 Magic' } },
            ['feet'] = { id = 24106, name = 'Ankusa Gaiters +4', stats = { 'DEF:96 HP+43 STR+27 DEX+34 VIT+27 AGI+47 MND+22 CHR+40 Accuracy+41 Attack+71 Magic Accurac' } },
        } },
        { set = 'Totemic', pieces = {
            ['head'] = { id = 23903, name = 'Totemic Helm +4', stats = { 'DEF:127 HP+74 MP+33 STR+33 DEX+39 VIT+30 AGI+39 INT+30 MND+33 CHR+34 Accuracy+57 Magic Acc' } },
            ['body'] = { id = 23948, name = 'Totemic Jackcoat +4', stats = { 'DEF:157 HP+108 MP+54 STR+39 DEX+44 VIT+34 AGI+43 INT+33 MND+36 CHR+38 Accuracy+60 Magic Ac' } },
            ['hands'] = { id = 23993, name = 'Totemic Gloves +4', stats = { 'DEF:115 HP+57 STR+21 DEX+50 VIT+42 AGI+20 INT+22 MND+43 CHR+30 Accuracy+58 Magic Accuracy+' } },
            ['legs'] = { id = 24038, name = 'Totemic Trousers +4', stats = { 'DEF:139 HP+90 STR+39 VIT+26 AGI+35 INT+40 MND+30 CHR+21 Accuracy+59 Magic Accuracy+59 Evas' } },
            ['feet'] = { id = 24083, name = 'Totemic Gaiters +4', stats = { 'DEF:97 HP+39 STR+22 DEX+39 VIT+22 AGI+52 MND+25 CHR+40 Accuracy+56 Magic Accuracy+56 Evasi' } },
        } },
    },
    -- COR
    ['COR'] = {
        { set = 'Laksamana', pieces = {
            ['head'] = { id = 23911, name = 'Laksamana Tricorne +4', stats = { 'DEF:125 HP+74 STR+33 DEX+39 VIT+27 AGI+44 INT+30 MND+33 CHR+31 Ranged Accuracy+66 Magic Ac' } },
            ['body'] = { id = 23956, name = 'Laksamana Frac +4', stats = { 'DEF:155 HP+108 MP+64 STR+39 DEX+44 VIT+31 AGI+50 INT+33 MND+36 CHR+33 Ranged Accuracy+67 R' } },
            ['feet'] = { id = 24091, name = 'Laksamana Bottes +4', stats = { 'DEF:95 HP+84 STR+22 DEX+39 VIT+20 AGI+54 MND+25 CHR+40 Ranged Accuracy+62 Magic Accuracy+6' } },
        } },
        { set = 'Laksamanas', pieces = {
            ['hands'] = { id = 24001, name = 'Laksamanas Gants +4', stats = { 'DEF:113 HP+57 MP+45 STR+21 DEX+50 VIT+39 AGI+22 INT+22 MND+43 CHR+27 Accuracy+40 Ranged Ac' } },
            ['legs'] = { id = 24046, name = 'Laksamanas Trews +4', stats = { 'DEF:137 HP+150 MP+83 STR+39 VIT+24 AGI+38 INT+40 MND+30 CHR+21 Attack+40 Ranged Accuracy+5' } },
        } },
        { set = 'Lanun', pieces = {
            ['head'] = { id = 23934, name = 'Lanun Tricorne +4', stats = { 'DEF:125 HP+90 STR+40 DEX+29 VIT+27 AGI+41 INT+28 MND+25 CHR+26 Ranged Accuracy+42br&gt', 'Ranged Attack+97 Magic Accuracy+42 Evasion+89 Magic Evasion+113 "Magic Def. Bonus"+5 Haste' } },
            ['body'] = { id = 23979, name = 'Lanun Frac +4', stats = { 'DEF:156 HP+89 MP+74 STR+42 DEX+39 VIT+36 AGI+43 INT+39 MND+33 CHR+33 Accuracy+54 Ranged At' } },
            ['hands'] = { id = 24024, name = 'Lanun Gants +4', stats = { 'DEF:114 HP+75 STR+31 DEX+45 VIT+44 AGI+22 INT+25 MND+40 CHR+27 Ranged Accuracy+49 Ranged A' } },
            ['legs'] = { id = 24069, name = 'Lanun Trews +4', stats = { 'DEF:137 HP+100 MP+53 STR+47 VIT+29 AGI+36 INT+43 MND+27 CHR+21 Attack+88 Ranged Accuracy+5' } },
            ['feet'] = { id = 24114, name = 'Lanun Bottes +4', stats = { 'DEF:93 HP+68 STR+27 DEX+34 VIT+25 AGI+49 INT+22 MND+22 CHR+40 Accuracy+48 Ranged Attack+71' } },
        } },
    },
    -- DNC
    ['DNC'] = {
        { set = 'Horos', pieces = {
            ['head'] = { id = 23936, name = 'Horos Tiara +4', stats = { 'DEF:128 HP+96 MP+53 STR+36 DEX+37 VIT+30 AGI+29 INT+28 MND+25 CHR+28 Accuracy+49 Attack+87' } },
            ['body'] = { id = 23981, name = 'Horos Casaque +4', stats = { 'DEF:158 HP+89 MP+74 STR+37 DEX+39 VIT+39 AGI+38 INT+36 MND+33 CHR+35 Accuracy+55 Attack+96' } },
            ['hands'] = { id = 24026, name = 'Horos Bangles +4', stats = { 'DEF:116 HP+95 STR+24 DEX+45 VIT+47 AGI+24 INT+25 MND+40 CHR+38 Accuracy+48 Attack+84 Magic' } },
            ['legs'] = { id = 24071, name = 'Horos Tights +4', stats = { 'DEF:138 HP+77 STR+45 VIT+31 AGI+30 INT+43 MND+27 CHR+26 Accuracy+50 Attack+74 Magic Accura' } },
            ['feet'] = { id = 24116, name = 'Horos Toe Shoes +4', stats = { 'DEF:96 HP+83 STR+25 DEX+34 VIT+27 AGI+47 MND+22 CHR+42 Accuracy+47 Attack+71 Magic Accurac' } },
        } },
        { set = 'Maxixi', pieces = {
            ['head'] = { id = 23914, name = 'maxixi tiara +4', stats = { 'DEF:127 HP+74 MP+43 STR+30 DEX+40 VIT+30 AGI+42 INT+30 MND+33 CHR+36 Accuracy+57 Magic Acc' } },
            ['body'] = { id = 23959, name = 'maxixi casaque +4', stats = { 'DEF:157 HP+108 MP+64 STR+34 DEX+45 VIT+34 AGI+46 INT+33 MND+36 CHR+35 Accuracy+66 Attack+3' } },
            ['hands'] = { id = 24004, name = 'maxixi bangles +4', stats = { 'DEF:115 HP+87 STR+21 DEX+48 VIT+42 AGI+28 INT+22 MND+43 CHR+29 Accuracy+58 Attack+40 Magic' } },
            ['legs'] = { id = 24049, name = 'maxixi tights +4', stats = { 'DEF:139 HP+90 STR+39 VIT+26 AGI+35 INT+40 MND+30 CHR+23 Accuracy+66 Attack+40 Magic Accura' } },
            ['feet'] = { id = 24094, name = 'maxixi toe shoes +4', stats = { 'DEF:97 HP+69 STR+22 DEX+37 VIT+22 AGI+52 MND+25 CHR+42 Accuracy+56 Attack+35 Magic Accurac' } },
        } },
    },
    -- DRG
    ['DRG'] = {
        { set = 'Pteroslaver', pieces = {
            ['head'] = { id = 23931, name = 'Pteroslaver Armet +4', stats = { 'DEF:136 HP+90 MP+53 STR+42 DEX+25 VIT+40 AGI+25 INT+27 MND+24 CHR+24 Accuracy+49 Attack+87' } },
            ['body'] = { id = 23976, name = 'Pteroslaver Mail +4', stats = { 'DEF:166 HP+112 MP+74 STR+49 DEX+39 VIT+41 AGI+31 INT+34 MND+31 CHR+31 Accuracy+45 Attack+9' } },
            ['legs'] = { id = 24066, name = 'Pteroslaver Brais +4', stats = { 'DEF:145 HP+95 STR+48 DEX+22 VIT+46 AGI+25 INT+39 MND+26 CHR+22 Accuracy+44 Attack+74 Magic' } },
            ['feet'] = { id = 24111, name = 'Pteroslaver Greaves +4', stats = { 'DEF:103 HP+65 MP+50 STR+33 DEX+27 VIT+30 AGI+42 MND+20 CHR+36 Accuracy+47 Attack+83 Magic ' } },
        } },
        { set = 'Pteroslaver Finger', pieces = {
            ['hands'] = { id = 24021, name = 'Pteroslaver Finger Gauntlets +4', stats = { 'DEF:121 HP+87 MP+60 STR+21 DEX+43 VIT+45 AGI+20 INT+23 MND+36 CHR+30 Accuracy+51 Attack+73' } },
        } },
        { set = 'Vishap', pieces = {
            ['head'] = { id = 23908, name = 'Vishap Armet +4', stats = { 'DEF:134 HP+77 MP+43 STR+37 DEX+35 VIT+35 AGI+35 INT+29 MND+35 CHR+29 Accuracy+57 Attack+47' } },
            ['body'] = { id = 23953, name = 'Vishap Mail +4', stats = { 'DEF:164 HP+111 MP+64 STR+41 DEX+36 VIT+41 AGI+36 INT+31 MND+34 CHR+31 Accuracy+67 Attack+4' } },
            ['legs'] = { id = 24043, name = 'Vishap Brais +4', stats = { 'DEF:146 HP+95 STR+43 DEX+25 VIT+29 AGI+30 INT+36 MND+29 CHR+22 Accuracy+59 Magic Accuracy+' } },
            ['feet'] = { id = 24088, name = 'Vishap Greaves +4', stats = { 'DEF:104 HP+57 STR+30 DEX+32 VIT+25 AGI+47 MND+23 CHR+36 Accuracy+56 Attack+35 Magic Accura' } },
        } },
        { set = 'Vishap Finger', pieces = {
            ['hands'] = { id = 23998, name = 'Vishap Finger Gauntlets +4', stats = { 'DEF:122 HP+60 STR+16 DEX+45 VIT+40 AGI+22 INT+20 MND+39 CHR+30 Accuracy+58 Attack+40 Magic' } },
        } },
    },
    -- DRK
    ['DRK'] = {
        { set = 'Fallens', pieces = {
            ['head'] = { id = 23925, name = 'Fallens Burgeonet +4', stats = { 'DEF:139 HP+106 MP+53 STR+45 DEX+24 VIT+45 AGI+24 INT+25 MND+22 CHR+22 Accuracy+49 Attack+8' } },
            ['body'] = { id = 23970, name = 'Fallens Cuirass +4', stats = { 'DEF:171 HP+113 MP+85 STR+47 DEX+32 VIT+44 AGI+29 INT+35 MND+32 CHR+29 Accuracy+53 Attack+9' } },
            ['legs'] = { id = 24060, name = 'Fallens Flanchard +4', stats = { 'DEF:155 HP+107 MP+55 STR+50 VIT+36 AGI+26 INT+43 MND+27 CHR+20 Accuracy+44 Attack+74 Magic' } },
            ['feet'] = { id = 24105, name = 'Fallens Sollerets +4', stats = { 'DEF:113 HP+48 STR+36 DEX+27 VIT+32 AGI+39 MND+20 CHR+36 Accuracy+41 Attack+86 Magic Accura' } },
        } },
        { set = 'Fallens Finger', pieces = {
            ['hands'] = { id = 24015, name = 'Fallens Finger Gauntlets +4', stats = { 'DEF:127 HP+59 STR+31 DEX+39 VIT+48 INT+27 MND+41 CHR+29 Accuracy+43 Attack+87 Magic Accura' } },
        } },
        { set = 'Ignominy', pieces = {
            ['head'] = { id = 23902, name = 'Ignominy Burgeonet +4', stats = { 'DEF:141 HP+81 MP+54 STR+38 DEX+34 VIT+35 AGI+34 INT+30 MND+30 CHR+27 Accuracy+57 Attack+43' } },
            ['body'] = { id = 23947, name = 'Ignominy Cuirass +4', stats = { 'DEF:171 HP+174 MP+132 STR+46 DEX+34 VIT+39 AGI+34 INT+29 MND+32 CHR+29 Accuracy+60 Attack+' } },
            ['legs'] = { id = 24037, name = 'Ignominy Flanchard +4', stats = { 'DEF:153 HP+98 STR+50 DEX+20 VIT+31 AGI+31 INT+40 MND+25 CHR+20 Accuracy+59 Attack+50 Magic' } },
            ['feet'] = { id = 24082, name = 'Ignominy Sollerets +4', stats = { 'DEF:111 HP+77 MP+50 STR+26 DEX+27 VIT+27 AGI+44 MND+23 CHR+36 Accuracy+64 Attack+45 Magic ' } },
        } },
        { set = 'Ignominy Finger', pieces = {
            ['hands'] = { id = 23992, name = 'Ignominy Finger Gauntlets +4', stats = { 'DEF:129 HP+86 MP+42 STR+25 DEX+49 VIT+43 INT+18 MND+38 CHR+29 Accuracy+64 Attack+38 Magic ' } },
        } },
    },
    -- GEO
    ['GEO'] = {
        { set = 'Bagua', pieces = {
            ['head'] = { id = 23938, name = 'Bagua Galero +4', stats = { 'DEF:123 HP+101 MP+62 STR+27 DEX+24 VIT+29 AGI+24 INT+34 MND+29 CHR+29 Accuracy+42 Magic Ac' } },
            ['body'] = { id = 23983, name = 'Bagua Tunic +4', stats = { 'DEF:154 HP+124 MP+129 STR+34 DEX+31 VIT+36 AGI+31 INT+44 MND+39 CHR+39 Accuracy+45 Magic A' } },
            ['hands'] = { id = 24028, name = 'Bagua Mitaines +4', stats = { 'DEF:109 HP+52 MP+44 STR+19 DEX+38 VIT+40 AGI+15 INT+34 MND+43 CHR+29 Accuracy+43 Magic Acc' } },
            ['legs'] = { id = 24073, name = 'Bagua Pants +4', stats = { 'DEF:133 HP+128 MP+59 STR+38 VIT+27 AGI+30 INT+52 MND+37 CHR+29 Accuracy+44 Magic Accuracy+' } },
            ['feet'] = { id = 24118, name = 'Bagua Sandals +4', stats = { 'DEF:92 HP+73 MP+44 STR+23 DEX+21 VIT+28 AGI+43 INT+35 MND+32 CHR+44 Accuracy+41 Magic Accu' } },
        } },
        { set = 'Geomancy', pieces = {
            ['head'] = { id = 23916, name = 'Geomancy Galero +4', stats = { 'DEF:122 HP+74 MP+89 STR+26 DEX+29 VIT+26 AGI+31 INT+36 MND+41 CHR+31 Accuracy+57 Magic Acc' } },
            ['body'] = { id = 23961, name = 'Geomancy Tunic +4', stats = { 'DEF:152 HP+101 MP+147 STR+31 DEX+34 VIT+31 AGI+36 INT+39 MND+44 CHR+39 Accuracy+60 Magic A' } },
            ['hands'] = { id = 24006, name = 'Geomancy Mitaines +4', stats = { 'DEF:110 HP+90 MP+78 STR+16 DEX+41 VIT+35 AGI+20 INT+29 MND+48 CHR+29 Accuracy+58 Magic Acc' } },
            ['legs'] = { id = 24051, name = 'Geomancy Pants +4', stats = { 'DEF:134 HP+137 MP+116 STR+35 VIT+22 AGI+32 INT+44 MND+39 CHR+29 Accuracy+59 Magic Accuracy' } },
            ['feet'] = { id = 24096, name = 'Geomancy Sandals +4', stats = { 'DEF:92 HP+39 MP+93 STR+20 DEX+24 VIT+20 AGI+48 INT+27 MND+34 CHR+44 Accuracy+56 Magic Accu' } },
        } },
    },
    -- MNK
    ['MNK'] = {
        { set = 'Anchorites', pieces = {
            ['head'] = { id = 23896, name = 'Anchorites Crown +4', stats = { 'DEF:125 HP+92 STR+33 DEX+35 VIT+32 AGI+37 INT+31 MND+37 CHR+31 Accuracy+57 Magic Accuracy+' } },
            ['body'] = { id = 23941, name = 'Anchorites Cyclas +4', stats = { 'DEF:155 HP+138 STR+39 DEX+40 VIT+36 AGI+40 INT+34 MND+37 CHR+34 Accuracy+65 Magic Accuracy' } },
            ['hands'] = { id = 23986, name = 'Anchorites Gloves +4', stats = { 'DEF:113 HP+100 STR+28 DEX+49 VIT+38 AGI+21 INT+20 MND+41 CHR+26 Accuracy+58 Magic Accuracy' } },
            ['legs'] = { id = 24031, name = 'Anchorites Hose +4', stats = { 'DEF:137 HP+114 STR+42 VIT+29 AGI+36 INT+42 MND+35 CHR+20 Accuracy+59 Magic Accuracy+59 Eva' } },
            ['feet'] = { id = 24076, name = 'Anchorites Gaiters +4', stats = { 'DEF:95 HP+46 STR+24 DEX+35 VIT+21 AGI+49 MND+30 CHR+39 Accuracy+56 Magic Accuracy+56 Evasi' } },
        } },
        { set = 'Hesychasts', pieces = {
            ['head'] = { id = 23919, name = 'Hesychasts Crown +4', stats = { 'DEF:113 HP+112 STR+35 DEX+30 VIT+37 AGI+26 INT+28 MND+25 CHR+25 Accuracy+42 Attack+72 Magi' } },
            ['body'] = { id = 23964, name = 'Hesychasts Cyclas +4', stats = { 'DEF:147 HP+132 STR+39 DEX+35 VIT+40 AGI+39 INT+37 MND+34 CHR+34 Accuracy+45 Attack+75 Magi' } },
            ['hands'] = { id = 24009, name = 'Hesychasts Gloves +4', stats = { 'DEF:101 HP+90 STR+25 DEX+44 VIT+43 AGI+16 INT+23 MND+38 CHR+26 Accuracy+54 Attack+96 Magic' } },
            ['legs'] = { id = 24054, name = 'Hesychasts Hose +4', stats = { 'DEF:129 HP+126 STR+47 DEX+21 VIT+29 AGI+31 INT+45 MND+27 CHR+20 Accuracy+44 Attack+74 Magi' } },
            ['feet'] = { id = 24099, name = 'Hesychasts Gaiters +4', stats = { 'DEF:86 HP+94 STR+33 DEX+29 VIT+26 AGI+44 MND+22 CHR+39 Accuracy+41 Attack+71 Magic Accurac' } },
        } },
    },
    -- NIN
    ['NIN'] = {
        { set = 'Hachiya', pieces = {
            ['head'] = { id = 23907, name = 'Hachiya Hatsuburi +4', stats = { 'DEF:127 HP+74 STR+33 DEX+38 VIT+32 AGI+37 INT+31 MND+34 CHR+31 Accuracy+64 Magic Accuracy+' } },
            ['body'] = { id = 23952, name = 'Hachiya Chainmail +4', stats = { 'DEF:157 HP+108 STR+39 DEX+40 VIT+36 AGI+40 INT+34 MND+37 CHR+34 Accuracy+60 Magic Accuracy' } },
            ['hands'] = { id = 23997, name = 'Hachiya Tekko +4', stats = { 'DEF:115 HP+57 STR+20 DEX+49 VIT+38 AGI+31 INT+20 MND+41 CHR+26 Accuracy+58 Ranged Accuracy' } },
            ['legs'] = { id = 24042, name = 'Hachiya Hakama +4', stats = { 'DEF:139 HP+90 STR+42 VIT+24 AGI+36 INT+42 MND+30 CHR+20 Accuracy+66 Ranged Accuracy+45 Mag' } },
            ['feet'] = { id = 24087, name = 'Hachiya Kyahan +4', stats = { 'DEF:97 HP+39 STR+24 DEX+30 VIT+21 AGI+49 INT+20 MND+25 CHR+39 Accuracy+62 Magic Accuracy+6' } },
        } },
        { set = 'Mochizuki', pieces = {
            ['head'] = { id = 23930, name = 'Mochizuki Hatsuburi +4', stats = { 'DEF:125 HP+66 STR+36 DEX+31 VIT+38 AGI+33 INT+35 MND+32 CHR+32 Accuracy+49 Attack+72 Magic' } },
            ['body'] = { id = 23975, name = 'Mochizuki Chainmail +4', stats = { 'DEF:159 HP+89 STR+39 DEX+35 VIT+36 AGI+35 INT+37 MND+34 CHR+34 Accuracy+56 Attack+97 Range' } },
            ['hands'] = { id = 24020, name = 'Mochizuki Tekko +4', stats = { 'DEF:114 HP+55 STR+35 DEX+44 VIT+42 AGI+16 INT+23 MND+38 CHR+26 Accuracy+43 Attack+89 Magic' } },
            ['legs'] = { id = 24065, name = 'Mochizuki Hakama +4', stats = { 'DEF:139 HP+92 STR+47 VIT+29 AGI+36 INT+45 MND+27 CHR+20 Accuracy+44 Attack+74 Magic Accura' } },
            ['feet'] = { id = 24110, name = 'Mochizuki Kyahan +4', stats = { 'DEF:98 HP+43 STR+33 DEX+29 VIT+30 AGI+48 MND+22 CHR+39 Accuracy+48 Attack+86 Magic Accurac' } },
        } },
    },
    -- PLD
    ['PLD'] = {
        { set = 'Caballarius', pieces = {
            ['head'] = { id = 23924, name = 'Caballarius Coronet +4', stats = { 'DEF:145 HP+126 MP+108 STR+37 DEX+26 VIT+48 AGI+26 INT+27 MND+24 CHR+24 Accuracy+42 Attack+' } },
            ['body'] = { id = 23969, name = 'Caballarius Surcoat +4', stats = { 'DEF:176 HP+148 MP+120 STR+44 DEX+29 VIT+44 AGI+29 INT+32 MND+29 CHR+29 Accuracy+45 Attack+' } },
            ['hands'] = { id = 24014, name = 'Caballarius Gauntlets +4', stats = { 'DEF:130 HP+134 STR+25 DEX+39 VIT+52 INT+21 MND+39 CHR+29 Accuracy+43 Attack+73 Magic Accur' } },
            ['legs'] = { id = 24059, name = 'Caballarius Breeches +4', stats = { 'DEF:156 HP+82 MP+110 STR+55 VIT+41 AGI+26 INT+38 MND+27 CHR+20 Accuracy+44 Attack+74 Magic' } },
            ['feet'] = { id = 24104, name = 'Caballarius Leggings +4', stats = { 'DEF:114 HP+73 MP+55 STR+31 DEX+22 VIT+32 AGI+39 MND+20 CHR+36 Accuracy+41 Attack+71 Magic ' } },
        } },
        { set = 'Reverence', pieces = {
            ['head'] = { id = 23901, name = 'Reverence Coronet +4', stats = { 'DEF:144 HP+81 MP+54 STR+35 DEX+34 VIT+38 AGI+34 INT+27 MND+33 CHR+27 Accuracy+57 Magic Acc' } },
            ['body'] = { id = 23946, name = 'Reverence Surcoat +4', stats = { 'DEF:174 HP+264 MP+72 STR+39 DEX+34 VIT+39 AGI+34 INT+29 MND+32 CHR+29 Accuracy+60 Magic Ac' } },
            ['hands'] = { id = 23991, name = 'Reverence Gauntlets +4', stats = { 'DEF:132 HP+123 STR+20 DEX+44 VIT+43 INT+18 MND+38 CHR+29 Accuracy+58 Magic Accuracy+58 Eva' } },
            ['legs'] = { id = 24036, name = 'Reverence Breeches +4', stats = { 'DEF:156 HP+173 MP+95 STR+45 VIT+31 AGI+31 INT+35 MND+25 CHR+20 Accuracy+59 Magic Accuracy+' } },
            ['feet'] = { id = 24081, name = 'Reverence Leggings +4', stats = { 'DEF:114 HP+92 MP+65 STR+26 DEX+27 VIT+27 AGI+44 MND+23 CHR+36 Accuracy+61 Magic Accuracy+6' } },
        } },
    },
    -- PUP
    ['PUP'] = {
        { set = 'Foire', pieces = {
            ['head'] = { id = 23912, name = 'Foire Taj +4', stats = { 'DEF:127 HP+74 STR+30 DEX+38 VIT+35 AGI+37 INT+31 MND+37 CHR+31 Accuracy+57 Magic Accuracy+' } },
            ['body'] = { id = 23957, name = 'Foire Tobe +4', stats = { 'DEF:157 HP+109 STR+34 DEX+40 VIT+31 AGI+40 INT+34 MND+37 CHR+34 Accuracy+67 Attack+40 Magi' } },
            ['hands'] = { id = 24002, name = 'Foire Dastanas +4', stats = { 'DEF:115 HP+80 STR+20 DEX+49 VIT+38 AGI+21 INT+20 MND+41 CHR+26 Accuracy+58 Magic Accuracy+' } },
            ['legs'] = { id = 24047, name = 'Foire Churidars +4', stats = { 'DEF:139 HP+143 STR+42 VIT+24 AGI+36 INT+42 MND+30 CHR+20 Accuracy+59 Magic Accuracy+59 Eva' } },
            ['feet'] = { id = 24092, name = 'Foire Babouches +4', stats = { 'DEF:97 HP+84 STR+24 DEX+30 VIT+21 AGI+49 MND+25 CHR+39 Accuracy+61 Magic Accuracy+61 Evasi' } },
        } },
        { set = 'Pitre', pieces = {
            ['head'] = { id = 23935, name = 'Pitre Taj +4', stats = { 'DEF:128 HP+66 STR+36 DEX+31 VIT+32 AGI+33 INT+29 MND+26 CHR+26 Accuracy+42 Attack+72 Magic' } },
            ['body'] = { id = 23980, name = 'Pitre Tobe +4', stats = { 'DEF:158 HP+110 STR+39 DEX+35 VIT+36 AGI+35 INT+37 MND+34 CHR+34 Accuracy+55 Attack+96 Magi' } },
            ['hands'] = { id = 24025, name = 'Pitre Dastanas +4', stats = { 'DEF:115 HP+55 STR+25 DEX+47 VIT+43 AGI+16 INT+23 MND+38 CHR+29 Accuracy+43 Attack+73 Magic' } },
            ['legs'] = { id = 24070, name = 'Pitre Churidars +4', stats = { 'DEF:138 HP+77 STR+50 VIT+32 AGI+31 INT+45 MND+27 CHR+20 Accuracy+51 Attack+74 Magic Accura' } },
            ['feet'] = { id = 24115, name = 'Pitre Babouches +4', stats = { 'DEF:96 HP+93 STR+29 DEX+25 VIT+26 AGI+44 INT+22 MND+22 CHR+39 Accuracy+41 Attack+71 Magic ' } },
        } },
    },
    -- RDM
    ['RDM'] = {
        { set = 'Atrophy', pieces = {
            ['head'] = { id = 23899, name = 'Atrophy Chapeau +4', stats = { 'DEF:121 HP+74 MP+68 STR+29 DEX+32 VIT+29 AGI+34 INT+37 MND+42 CHR+34 Accuracy+64 Magic Acc' } },
            ['body'] = { id = 23944, name = 'Atrophy Tabard +4', stats = { 'DEF:151 HP+101 MP+108 STR+31 DEX+34 VIT+31 AGI+36 INT+43 MND+48 CHR+39 Accuracy+65 Magic A' } },
            ['hands'] = { id = 23989, name = 'Atrophy Gloves +4', stats = { 'DEF:109 HP+53 MP+41 STR+21 DEX+46 VIT+35 AGI+20 INT+29 MND+48 CHR+29 Accuracy+63 Attack+35' } },
            ['legs'] = { id = 24034, name = 'Atrophy Tights +4', stats = { 'DEF:133 HP+84 MP+63 STR+35 VIT+22 AGI+32 INT+44 MND+44 CHR+29 Accuracy+59 Magic Accuracy+5' } },
            ['feet'] = { id = 24079, name = 'Atrophy Boots +4', stats = { 'DEF:91 HP+92 MP+93 STR+20 DEX+24 VIT+20 AGI+48 INT+27 MND+34 CHR+44 Accuracy+66 Magic Accu' } },
        } },
        { set = 'Vitiation', pieces = {
            ['head'] = { id = 23922, name = 'Vitiation Chapeau +4', stats = { 'DEF:123 HP+91 MP+87 STR+27 DEX+24 VIT+29 AGI+24 INT+34 MND+42 CHR+29 Accuracy+42 Attack+72' } },
            ['body'] = { id = 23967, name = 'Vitiation Tabard +4', stats = { 'DEF:151 HP+84 MP+109 STR+34 DEX+31 VIT+36 AGI+31 INT+44 MND+45 CHR+39 Accuracy+45 Attack+7' } },
            ['hands'] = { id = 24012, name = 'Vitiation Gloves +4', stats = { 'DEF:108 HP+52 MP+74 STR+19 DEX+38 VIT+40 AGI+15 INT+37 MND+46 CHR+29 Accuracy+43 Attack+73' } },
            ['legs'] = { id = 24057, name = 'Vitiation Tights +4', stats = { 'DEF:134 HP+73 MP+59 STR+38 DEX+22 VIT+27 AGI+27 INT+49 MND+34 CHR+29 Accuracy+44 Attack+74' } },
            ['feet'] = { id = 24102, name = 'Vitiation Boots +4', stats = { 'DEF:92 HP+43 MP+75 STR+21 DEX+19 VIT+23 AGI+41 INT+35 MND+32 CHR+42 Accuracy+41 Magic Accu' } },
        } },
    },
    -- RNG
    ['RNG'] = {
        { set = 'Arcadian', pieces = {
            ['head'] = { id = 23928, name = 'Arcadian Beret +4', stats = { 'DEF:125 HP+66 STR+36 DEX+29 VIT+27 AGI+37 INT+28 MND+31 CHR+26 Ranged Accuracy+42 Ranged A' } },
            ['body'] = { id = 23973, name = 'Arcadian Jerkin +4', stats = { 'DEF:156 HP+89 MP+74 STR+42 DEX+39 VIT+36 AGI+43 INT+36 MND+33 CHR+33 Ranged Accuracy+45 Ra' } },
            ['hands'] = { id = 24018, name = 'Arcadian Bracers +4', stats = { 'DEF:111 HP+55 STR+30 DEX+45 VIT+44 AGI+21 INT+25 MND+40 CHR+27 Ranged Accuracy+43 Ranged A' } },
            ['legs'] = { id = 24063, name = 'arcadian braccae +4', stats = { 'DEF:135 HP+97 MP+53 STR+44 VIT+29 AGI+33 INT+43 MND+27 CHR+21 Ranged Accuracy+52 Ranged At' } },
            ['feet'] = { id = 24108, name = 'Arcadian Socks +4', stats = { 'DEF:93 HP+43 STR+29 DEX+34 VIT+25 AGI+51 MND+22 CHR+40 Ranged Accuracy+41 Ranged Attack+91' } },
        } },
        { set = 'Orion', pieces = {
            ['head'] = { id = 23905, name = 'Orion Beret +4', stats = { 'DEF:124 HP+74 STR+33 DEX+39 VIT+27 AGI+44 INT+30 MND+33 CHR+31 Ranged Accuracy+57 Ranged A' } },
            ['body'] = { id = 23950, name = 'Orion Jerkin +4', stats = { 'DEF:154 HP+108 MP+64 STR+34 DEX+44 VIT+31 AGI+45 INT+33 MND+36 CHR+33 Ranged Accuracy+70 R' } },
            ['hands'] = { id = 23995, name = 'Orion Bracers +4', stats = { 'DEF:112 HP+57 STR+21 DEX+50 VIT+39 AGI+32 INT+22 MND+43 CHR+27 Ranged Accuracy+58 Magic Ac' } },
            ['legs'] = { id = 24040, name = 'Orion Braccae +4', stats = { 'DEF:136 HP+90 MP+43 STR+39 VIT+24 AGI+42 INT+40 MND+34 CHR+21 Ranged Accuracy+66 Magic Acc' } },
            ['feet'] = { id = 24085, name = 'Orion Socks +4', stats = { 'DEF:94 HP+39 STR+22 DEX+39 VIT+20 AGI+54 MND+25 CHR+40 Ranged Accuracy+64 Ranged Attack+41' } },
        } },
    },
    -- RUN
    ['RUN'] = {
        { set = 'Futhark', pieces = {
            ['head'] = { id = 23939, name = 'Futhark Bandeau +4', stats = { 'DEF:129 HP+66 MP+98 STR+26 DEX+27 VIT+35 AGI+34 INT+28 MND+23 CHR+24 Accuracy+42 Attack+72' } },
            ['body'] = { id = 23984, name = 'Futhark Coat +4', stats = { 'DEF:161 HP+129 MP+114 STR+37 DEX+39 VIT+39 AGI+38 INT+38 MND+33 CHR+33 Accuracy+45 Attack+' } },
            ['hands'] = { id = 24029, name = 'Futhark Mitons +4', stats = { 'DEF:117 HP+55 STR+24 DEX+45 VIT+47 AGI+15 INT+27 MND+40 CHR+27 Accuracy+43 Attack+91 Magic' } },
            ['legs'] = { id = 24074, name = 'Futhark Trousers +4', stats = { 'DEF:144 HP+117 STR+42 VIT+31 AGI+30 INT+45 MND+27 CHR+21 Accuracy+44 Attack+74 Magic Accur' } },
            ['feet'] = { id = 24119, name = 'Futhark Boots +4', stats = { 'DEF:100 HP+43 MP+60 STR+25 DEX+34 VIT+27 AGI+47 MND+22 CHR+40 Accuracy+50 Attack+71 Magic ' } },
        } },
        { set = 'Runeist', pieces = {
            ['head'] = { id = 23917, name = 'Runeist Bandeau +4', stats = { 'DEF:130 HP+119 MP+99 STR+31 DEX+38 VIT+31 AGI+40 INT+31 MND+36 CHR+32 Accuracy+57 Magic Ac' } },
            ['body'] = { id = 23962, name = 'Runeist Coat +4', stats = { 'DEF:160 HP+228 MP+86 STR+34 DEX+42 VIT+34 AGI+43 INT+33 MND+38 CHR+33 All resistances+39 A' } },
            ['hands'] = { id = 24007, name = 'Runeist Mitons +4', stats = { 'DEF:118 HP+95 MP+57 STR+21 DEX+48 VIT+42 AGI+20 INT+22 MND+45 CHR+27 Accuracy+58 Magic Acc' } },
            ['legs'] = { id = 24052, name = 'Runeist Trousers +4', stats = { 'DEF:142 HP+90 MP+72 STR+39 VIT+26 AGI+35 INT+40 MND+33 CHR+21 Accuracy+59 Magic Accuracy+5' } },
            ['feet'] = { id = 24097, name = 'Runeist Boots +4', stats = { 'DEF:100 HP+84 STR+22 DEX+37 VIT+22 AGI+52 MND+27 CHR+40 Accuracy+56 Magic Accuracy+56 Evas' } },
        } },
    },
    -- SAM
    ['SAM'] = {
        { set = 'Sakonji', pieces = {
            ['head'] = { id = 23929, name = 'Sakonji Kabuto +4', stats = { 'DEF:140 HP+88 MP+53 STR+39 DEX+30 VIT+37 AGI+30 INT+32 MND+29 CHR+29 Accuracy+50 Attack+89' } },
            ['body'] = { id = 23974, name = 'Sakonji Domaru +4', stats = { 'DEF:170 HP+111 MP+74 STR+47 DEX+37 VIT+41 AGI+31 INT+34 MND+31 CHR+31 Accuracy+52 Attack+9' } },
            ['hands'] = { id = 24019, name = 'Sakonji Kote +4', stats = { 'DEF:130 HP+57 STR+21 DEX+40 VIT+45 AGI+17 INT+23 MND+36 CHR+30 Accuracy+52 Attack+91 Magic' } },
            ['legs'] = { id = 24064, name = 'Sakonji Haidate +4', stats = { 'DEF:150 HP+80 STR+48 VIT+34 AGI+25 INT+39 MND+26 CHR+22 Accuracy+44 Attack+92 Magic Accura' } },
            ['feet'] = { id = 24109, name = 'Sakonji Sune-Ate +4', stats = { 'DEF:111 HP+75 STR+36 DEX+27 VIT+30 AGI+42 MND+20 CHR+36 Accuracy+41 Attack+94 Magic Accura' } },
        } },
        { set = 'Wakido', pieces = {
            ['head'] = { id = 23906, name = 'Wakido Kabuto +4', stats = { 'DEF:140 HP+77 MP+43 STR+37 DEX+38 VIT+32 AGI+35 INT+29 MND+32 CHR+29 Accuracy+57 Attack+46' } },
            ['body'] = { id = 23951, name = 'Wakido Domaru +4', stats = { 'DEF:170 HP+111 MP+64 STR+41 DEX+36 VIT+41 AGI+36 INT+31 MND+34 CHR+31 Accuracy+67 Magic Ac' } },
            ['hands'] = { id = 23996, name = 'Wakido Kote +4', stats = { 'DEF:128 HP+60 STR+24 DEX+45 VIT+40 AGI+22 INT+20 MND+40 CHR+30 Accuracy+58 Magic Accuracy+' } },
            ['legs'] = { id = 24041, name = 'Wakido Haidate +4', stats = { 'DEF:152 HP+95 STR+44 VIT+29 AGI+30 INT+37 MND+29 CHR+22 Accuracy+59 Attack+45 Ranged Attac' } },
            ['feet'] = { id = 24086, name = 'Wakido Sune-Ate +4', stats = { 'DEF:110 HP+42 STR+25 DEX+33 VIT+25 AGI+47 MND+23 CHR+37 Accuracy+66 Attack+43 Ranged Accur' } },
        } },
    },
    -- SCH
    ['SCH'] = {
        { set = 'Academics', pieces = {
            ['head'] = { id = 23915, name = 'Academics Mortarboard +4', stats = { 'DEF:118 HP+74 MP+68 STR+29 DEX+32 VIT+29 AGI+34 INT+37 MND+42 CHR+34 Accuracy+62 Magic Acc' } },
            ['body'] = { id = 23960, name = 'Academics Gown +4', stats = { 'DEF:148 HP+101 MP+183 STR+31 DEX+34 VIT+31 AGI+36 INT+44 MND+44 CHR+39 Accuracy+60 Magic A' } },
            ['hands'] = { id = 24005, name = 'Academics Bracers +4', stats = { 'DEF:106 HP+53 MP+71 STR+16 DEX+41 VIT+35 AGI+20 INT+29 MND+48 CHR+29 Accuracy+58 Magic Acc' } },
            ['legs'] = { id = 24050, name = 'Academics Pants +4', stats = { 'DEF:130 HP+99 MP+78 STR+35 VIT+22 AGI+32 INT+44 MND+44 CHR+29 Accuracy+59 Magic Accuracy+5' } },
            ['feet'] = { id = 24095, name = 'Academics Loafers +4', stats = { 'DEF:88 HP+39 MP+41 STR+20 DEX+24 VIT+20 AGI+48 INT+32 MND+34 CHR+44 Accuracy+56 Magic Accu' } },
        } },
        { set = 'Pedagogy', pieces = {
            ['head'] = { id = 23937, name = 'Pedagogy Mortarboard +4', stats = { 'DEF:117 HP+96 MP+92 STR+27 DEX+24 VIT+29 AGI+24 INT+44 MND+39 CHR+29 Accuracy+42 Magic Acc' } },
            ['body'] = { id = 23982, name = 'Pedagogy Gown +4', stats = { 'DEF:149 HP+109 MP+114 STR+34 DEX+31 VIT+36 AGI+31 INT+44 MND+39 CHR+39 Accuracy+45 Magic A' } },
            ['hands'] = { id = 24027, name = 'Pedagogy Bracers +4', stats = { 'DEF:105 HP+52 MP+85 STR+19 DEX+38 VIT+40 AGI+15 INT+37 MND+46 CHR+29 Accuracy+43 Magic Acc' } },
            ['legs'] = { id = 24072, name = 'Pedagogy Pants +4', stats = { 'DEF:131 HP+93 MP+79 STR+38 VIT+27 AGI+27 INT+52 MND+34 CHR+29 Accuracy+44 Magic Accuracy+4' } },
            ['feet'] = { id = 24117, name = 'Pedagogy Loafers +4', stats = { 'DEF:89 HP+43 MP+69 STR+23 DEX+21 VIT+25 AGI+43 INT+32 MND+29 CHR+44 Accuracy+41 Magic Accu' } },
        } },
    },
    -- SMN
    ['SMN'] = {
        { set = 'Convokers', pieces = {
            ['head'] = { id = 23909, name = 'Convokers Horn +4', stats = { 'DEF:117 HP+66 MP+108 STR+22 DEX+29 VIT+24 AGI+29 INT+29 MND+32 CHR+29 Accuracy+57 Magic Ac' } },
            ['hands'] = { id = 23999, name = 'Convokers Bracers +4', stats = { 'DEF:105 HP+47 MP+96 STR+16 DEX+43 VIT+34 AGI+20 INT+29 MND+46 CHR+29 Accuracy+58 Magic Acc' } },
            ['legs'] = { id = 24044, name = 'Convokers Spats +4', stats = { 'DEF:129 HP+77 MP+119 STR+35 VIT+21 AGI+32 INT+44 MND+37 CHR+29 Accuracy+59 Magic Accuracy+' } },
            ['feet'] = { id = 24089, name = 'Convokers Pigaches +4', stats = { 'DEF:87 HP+33 MP+81 STR+20 DEX+26 VIT+20 AGI+47 INT+27 MND+32 CHR+44 Accuracy+56 Magic Accu' } },
        } },
        { set = 'Glyphic', pieces = {
            ['head'] = { id = 23932, name = 'Glyphic Horn +4', stats = { 'DEF:118 HP+61 MP+125 STR+27 DEX+24 VIT+29 AGI+24 INT+32 MND+29 CHR+29 Accuracy+42 Attack+7' } },
            ['body'] = { id = 23977, name = 'Glyphic Doublet +4', stats = { 'DEF:148 HP+80 MP+145 STR+36 DEX+30 VIT+36 AGI+31 INT+42 MND+39 CHR+39 Accuracy+45 Attack+7' } },
            ['hands'] = { id = 24022, name = 'Glyphic Bracers +4', stats = { 'DEF:106 HP+48 MP+71 STR+21 DEX+38 VIT+39 AGI+15 INT+32 MND+43 CHR+29 Accuracy+43 Attack+73' } },
            ['legs'] = { id = 24067, name = 'Glyphic Spats +4', stats = { 'DEF:128 HP+68 MP+115 STR+40 VIT+26 AGI+27 INT+47 MND+34 CHR+29 Accuracy+44 Attack+74 Magic' } },
            ['feet'] = { id = 24112, name = 'Glyphic Pigaches +4', stats = { 'DEF:85 HP+39 MP+105 STR+25 DEX+21 VIT+25 AGI+42 INT+30 MND+29 CHR+44 Accuracy+41 Attack+71' } },
        } },
    },
    -- THF
    ['THF'] = {
        { set = 'Pillagers', pieces = {
            ['head'] = { id = 23900, name = 'Pillagers Bonnet +4', stats = { 'DEF:126 HP+74 MP+43 STR+30 DEX+42 VIT+30 AGI+42 INT+30 MND+33 CHR+31 Accuracy+63 Ranged Ac' } },
            ['body'] = { id = 23945, name = 'Pillagers Vest +4', stats = { 'DEF:156 HP+108 MP+64 STR+34 DEX+49 VIT+34 AGI+43 INT+33 MND+36 CHR+33 Accuracy+70 Magic Ac' } },
            ['hands'] = { id = 23990, name = 'Pillagers Armlets +4', stats = { 'DEF:114 HP+57 STR+21 DEX+50 VIT+42 AGI+30 INT+22 MND+43 CHR+27 Accuracy+58 Magic Accuracy+' } },
            ['legs'] = { id = 24035, name = 'Pillagers Culottes +4', stats = { 'DEF:138 HP+90 STR+39 DEX+20 VIT+26 AGI+35 INT+40 MND+30 CHR+21 Accuracy+64 Attack+35 Magic' } },
            ['feet'] = { id = 24080, name = 'Pillagers Poulaines +4', stats = { 'DEF:96 HP+39 STR+22 DEX+39 VIT+22 AGI+52 MND+25 CHR+40 Accuracy+62 Ranged Accuracy+43 Magi' } },
        } },
        { set = 'Plunderers', pieces = {
            ['head'] = { id = 23923, name = 'Plunderers Bonnet +4', stats = { 'DEF:127 HP+66 MP+53 STR+36 DEX+41 VIT+36 AGI+35 INT+34 MND+31 CHR+32 Accuracy+49 Attack+72' } },
            ['body'] = { id = 23968, name = 'Plunderers Vest +4', stats = { 'DEF:157 HP+89 MP+74 STR+46 DEX+46 VIT+39 AGI+45 INT+36 MND+33 CHR+33 Accuracy+45 Attack+75' } },
            ['hands'] = { id = 24013, name = 'Plunderers Armlets +4', stats = { 'DEF:115 HP+55 STR+24 DEX+43 VIT+45 AGI+13 INT+23 MND+38 CHR+34 Accuracy+50 Attack+73 Magic' } },
            ['legs'] = { id = 24058, name = 'Plunderers Culottes +4', stats = { 'DEF:135 HP+77 STR+47 DEX+21 VIT+34 AGI+33 INT+46 MND+30 CHR+24 Accuracy+51 Attack+74 Magic' } },
            ['feet'] = { id = 24103, name = 'Plunderers Poulaines +4', stats = { 'DEF:97 HP+43 STR+27 DEX+37 VIT+27 AGI+47 MND+22 CHR+43 Accuracy+41 Attack+71 Magic Accurac' } },
        } },
    },
    -- WAR
    ['WAR'] = {
        { set = 'Agoge', pieces = {
            ['head'] = { id = 23918, name = 'Agoge Mask +4', stats = { 'DEF:140 HP+68 STR+40 DEX+28 VIT+40 AGI+28 INT+31 MND+28 CHR+28 Accuracy+42 Attack+93 Magic' } },
            ['body'] = { id = 23963, name = 'Agoge Lorica +4', stats = { 'DEF:170 HP+91 STR+41 DEX+35 VIT+41 AGI+30 INT+33 MND+30 CHR+30 Accuracy+55 Attack+95 Magic' } },
            ['hands'] = { id = 24008, name = 'Agoge Mufflers +4', stats = { 'DEF:124 HP+80 STR+30 DEX+39 VIT+52 AGI+13 INT+24 MND+36 CHR+26 Accuracy+43 Attack+96 Magic' } },
            ['legs'] = { id = 24053, name = 'Agoge Cuisses +4', stats = { 'DEF:151 HP+80 STR+48 VIT+35 AGI+24 INT+39 MND+23 CHR+23 Accuracy+44 Attack+74 Magic Accura' } },
            ['feet'] = { id = 24098, name = 'Agoge Calligae +4', stats = { 'DEF:106 HP+45 STR+32 DEX+29 VIT+33 AGI+43 MND+21 CHR+38 Accuracy+48 Attack+71 Magic Accura' } },
        } },
        { set = 'Pummelers', pieces = {
            ['head'] = { id = 23895, name = 'Pummelers Mask +4', stats = { 'DEF:138 HP+77 STR+31 DEX+39 VIT+34 AGI+36 INT+31 MND+34 CHR+31 Accuracy+57 Magic Accuracy+' } },
            ['body'] = { id = 23940, name = 'Pummelers Lorica +4', stats = { 'DEF:168 HP+111 STR+40 DEX+39 VIT+40 AGI+38 INT+33 MND+36 CHR+33 Accuracy+60 Attack+37 Magi' } },
            ['hands'] = { id = 23985, name = 'Pummelers Mufflers +4', stats = { 'DEF:126 HP+75 STR+28 DEX+47 VIT+42 AGI+21 INT+24 MND+42 CHR+29 Accuracy+58 Magic Accuracy+' } },
            ['legs'] = { id = 24030, name = 'Pummelers Cuisses +4', stats = { 'DEF:150 HP+95 STR+40 VIT+27 AGI+32 INT+39 MND+29 CHR+26 Accuracy+66 Magic Accuracy+66 Evas' } },
            ['feet'] = { id = 24075, name = 'Pummelers Calligae +4', stats = { 'DEF:108 HP+65 STR+24 DEX+31 VIT+31 AGI+48 MND+24 CHR+38 Accuracy+56 Attack+45 Magic Accura' } },
        } },
    },
    -- WHM
    ['WHM'] = {
        { set = 'Piety', pieces = {
            ['head'] = { id = 23920, name = 'Piety Cap +4', stats = { 'DEF:119 HP+66 MP+95 STR+29 DEX+26 VIT+36 AGI+26 INT+36 MND+36 CHR+31 Accuracy+42 Attack+72' } },
            ['body'] = { id = 23965, name = 'Piety Bliaut +4', stats = { 'DEF:149 HP+84 MP+115 STR+34 DEX+31 VIT+36 AGI+31 INT+44 MND+39 CHR+39 Accuracy+45 Attack+7' } },
            ['hands'] = { id = 24010, name = 'Piety Mitts +4', stats = { 'DEF:110 HP+82 MP+74 STR+19 DEX+38 VIT+40 AGI+15 INT+34 MND+43 CHR+29 Accuracy+43 Attack+73' } },
            ['legs'] = { id = 24055, name = 'Piety Pantaloons +4', stats = { 'DEF:132 HP+103 MP+89 STR+38 VIT+27 AGI+27 INT+49 MND+34 CHR+29 Accuracy+44 Attack+74 Magic' } },
            ['feet'] = { id = 24100, name = 'Piety Duckbills +4', stats = { 'DEF:91 HP+68 MP+69 STR+23 DEX+21 VIT+25 AGI+43 INT+32 MND+29 CHR+44 Accuracy+41 Attack+71 ' } },
        } },
        { set = 'Theophany', pieces = {
            ['head'] = { id = 23897, name = 'Theophany Cap +4', stats = { 'DEF:120 HP+74 MP+68 STR+29 DEX+32 VIT+29 AGI+34 INT+34 MND+42 CHR+34 Accuracy+57 Magic Acc' } },
            ['body'] = { id = 23942, name = 'Theophany Bliaut +4', stats = { 'DEF:150 HP+101 MP+108 STR+31 DEX+34 VIT+31 AGI+36 INT+39 MND+44 CHR+39 Accuracy+60 Magic A' } },
            ['hands'] = { id = 23987, name = 'Theophany Mitts +4', stats = { 'DEF:108 HP+53 MP+93 STR+21 DEX+41 VIT+35 AGI+20 INT+29 MND+53 CHR+29 Accuracy+58 Magic Acc' } },
            ['legs'] = { id = 24032, name = 'theophany pantaloons +4', stats = { 'DEF:132 HP+84 MP+63 STR+35 VIT+22 AGI+32 INT+44 MND+39 CHR+29 Accuracy+59 Magic Accuracy+5' } },
            ['feet'] = { id = 24077, name = 'Theophany Duckbills +4', stats = { 'DEF:90 HP+84 MP+86 STR+20 DEX+24 VIT+20 AGI+53 INT+32 MND+39 CHR+44 Accuracy+56 Magic Accu' } },
        } },
    },
}

-- INFAMY_TYPEMAP:BEGIN
-- AUTO-GENERATED by tools/build_infamy_typemap.py -- do NOT hand-edit.
-- Maps curated Infamy Vendor item ids to 'Category/Subtype' for the
-- grouped browser (derived from item_equipment.slot + item_weapon.skill).
-- Re-run the tool after adding items; unmapped ids show under 'Other'.
catalog.itemTypeMap =
{
    [21632] = 'Weapons/Sword',
    [21621] = 'Weapons/Sword',
    [21535] = 'Weapons/Hand-to-Hand',
    [21590] = 'Weapons/Dagger',
    [21646] = 'Weapons/Sword',
    [21653] = 'Weapons/Great Sword',
    [21730] = 'Weapons/Axe',
    [21785] = 'Weapons/Great Axe',
    [21837] = 'Weapons/Scythe',
    [21891] = 'Weapons/Polearm',
    [21932] = 'Weapons/Katana',
    [21986] = 'Weapons/Great Katana',
    [22002] = 'Weapons/Club',
    [22106] = 'Weapons/Staff',
    [22163] = 'Weapons/Archery',
    [22164] = 'Weapons/Marksmanship',
    [26495] = 'Weapons/Grip-Shield',
    [22307] = 'Weapons/Instrument',
    [23500] = 'Armor/Body',
    [23567] = 'Armor/Hands',
    [25953] = 'Armor/Feet',
    [22212] = 'Weapons/Grip-Shield',
    [21431] = 'Accessories/Ear',
    [26022] = 'Accessories/Neck',
    [26118] = 'Accessories/Ear',
    [26084] = 'Accessories/Ear',
    [26185] = 'Accessories/Ring',
    [26190] = 'Accessories/Ring',
    [26334] = 'Accessories/Waist',
    [26259] = 'Accessories/Back',
    [27928] = 'Armor/Hands',
    [13566] = 'Accessories/Ring',
    [19832] = 'Weapons/Polearm',
    [16199] = 'Weapons/Grip-Shield',
    [21602] = 'Weapons/Sword',
    [23734] = 'Armor/Hands',
    [25578] = 'Armor/Head',
    [25794] = 'Armor/Body',
    [25603] = 'Armor/Head',
    [28330] = 'Armor/Feet',
    [25809] = 'Armor/Hands',
    [25868] = 'Armor/Legs',
    [25934] = 'Armor/Feet',
    [11007] = 'Accessories/Back',
    [26015] = 'Accessories/Neck',
    [26003] = 'Accessories/Neck',
    [27595] = 'Accessories/Back',
    [28420] = 'Accessories/Waist',
    [27510] = 'Accessories/Neck',
    [22281] = 'Weapons/Ammo',
    [26227] = 'Accessories/Ring',
    [20672] = 'Weapons/Sword',
    [22042] = 'Weapons/Club',
    [22055] = 'Weapons/Staff',
    [22040] = 'Weapons/Club',
    [22081] = 'Weapons/Staff',
    [22086] = 'Weapons/Staff',
    [21071] = 'Weapons/Club',
    [22058] = 'Weapons/Staff',
    [21830] = 'Weapons/Scythe',
    [22031] = 'Weapons/Club',
    [21637] = 'Weapons/Sword',
    [21565] = 'Weapons/Dagger',
    [21829] = 'Weapons/Scythe',
    [21564] = 'Weapons/Dagger',
    [21620] = 'Weapons/Sword',
    [21563] = 'Weapons/Dagger',
    [21828] = 'Weapons/Scythe',
    [26963] = 'Armor/Body',
    [23716] = 'Armor/Body',
    [25799] = 'Armor/Body',
    [23765] = 'Armor/Body',
    [23764] = 'Armor/Body',
    [25888] = 'Armor/Legs',
    [23781] = 'Armor/Legs',
    [23779] = 'Armor/Legs',
    [25571] = 'Armor/Head',
    [25837] = 'Armor/Hands',
    [23724] = 'Armor/Legs',
    [23778] = 'Armor/Legs',
    [23774] = 'Armor/Hands',
    [23760] = 'Armor/Head',
    [25955] = 'Armor/Feet',
    [23788] = 'Armor/Feet',
    [23757] = 'Armor/Head',
    [23772] = 'Armor/Hands',
    [23771] = 'Armor/Hands',
    [23758] = 'Armor/Head',
    [23712] = 'Armor/Head',
    [23773] = 'Armor/Hands',
    [21779] = 'Weapons/Great Axe',
    [23787] = 'Armor/Feet',
    [23785] = 'Armor/Feet',
    [23786] = 'Armor/Feet',
    [21975] = 'Weapons/Great Katana',
    [21778] = 'Weapons/Great Axe',
    [21674] = 'Weapons/Great Sword',
    [21883] = 'Weapons/Polearm',
    [21567] = 'Weapons/Dagger',
    [21974] = 'Weapons/Great Katana',
    [21683] = 'Weapons/Great Sword',
    [21964] = 'Weapons/Great Katana',
    [21870] = 'Weapons/Polearm',
    [21673] = 'Weapons/Great Sword',
    [21882] = 'Weapons/Polearm',
    [21519] = 'Weapons/Hand-to-Hand',
    [21766] = 'Weapons/Great Axe',
    [21816] = 'Weapons/Scythe',
    [21819] = 'Weapons/Scythe',
    [21527] = 'Weapons/Hand-to-Hand',
    [21768] = 'Weapons/Great Axe',
    [21663] = 'Weapons/Great Sword',
    [26023] = 'Accessories/Neck',
    [21707] = 'Weapons/Axe',
    [21722] = 'Weapons/Axe',
    [21777] = 'Weapons/Great Axe',
    [21518] = 'Weapons/Hand-to-Hand',
    [21872] = 'Weapons/Polearm',
    [21881] = 'Weapons/Polearm',
    [21973] = 'Weapons/Great Katana',
    [21528] = 'Weapons/Hand-to-Hand',
    [21721] = 'Weapons/Axe',
    [21709] = 'Weapons/Axe',
    [22115] = 'Weapons/Archery',
    [27620] = 'Accessories/Back',
    [26357] = 'Accessories/Waist',
    [22107] = 'Weapons/Archery',
    [26269] = 'Accessories/Back',
    [21752] = 'Weapons/Axe',
    [26341] = 'Accessories/Waist',
    [21972] = 'Weapons/Great Katana',
    [27615] = 'Accessories/Back',
    [22129] = 'Weapons/Archery',
    [21296] = 'Weapons/Ammo',
    [21227] = 'Weapons/Archery',
    [21269] = 'Weapons/Marksmanship',
    [22126] = 'Weapons/Archery',
    [22136] = 'Weapons/Marksmanship',
    [26004] = 'Accessories/Neck',
    [21325] = 'Weapons/Ammo',
    [26361] = 'Accessories/Waist',
    [13655] = 'Accessories/Back',
    [11607] = 'Accessories/Neck',
    [26359] = 'Accessories/Waist',
    [25461] = 'Accessories/Neck',
    [26191] = 'Accessories/Ring',
    [25497] = 'Accessories/Neck',
    [28607] = 'Accessories/Back',
    [26088] = 'Accessories/Ear',
    [28471] = 'Accessories/Ring',
    [26186] = 'Accessories/Ring',
    [25439] = 'Accessories/Ear',
    [25535] = 'Accessories/Ear',
    [26108] = 'Accessories/Ear',
    [25422] = 'Accessories/Ear',
    [25428] = 'Accessories/Ear',
    [25434] = 'Accessories/Ear',
    [25440] = 'Accessories/Ear',
    [25446] = 'Accessories/Ear',
    [25452] = 'Accessories/Ear',
    [25458] = 'Accessories/Ear',
    [25464] = 'Accessories/Ear',
    [25470] = 'Accessories/Ear',
    [25476] = 'Accessories/Ear',
    [25482] = 'Accessories/Ear',
    [25488] = 'Accessories/Ear',
    [25494] = 'Accessories/Ear',
    [25500] = 'Accessories/Ear',
    [25506] = 'Accessories/Ear',
    [25512] = 'Accessories/Ear',
    [25518] = 'Accessories/Ear',
    [25524] = 'Accessories/Ear',
    [25530] = 'Accessories/Ear',
    [25536] = 'Accessories/Ear',
    [25542] = 'Accessories/Ear',
    [25548] = 'Accessories/Ear',
}
-- INFAMY_TYPEMAP:END


return catalog
