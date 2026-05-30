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
-- (zero mob_groups rows). No SQL changes needed — we reuse the HL
-- mob_groups (registered in zone 210 / GM_Home) via `groupZoneId`
-- so the engine resolves them without needing local zone rows.
--
-- Tuning knobs (everything in this file):
--   timeLimit         seconds to kill the boss. miss it → abort.
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

-- HL groupZoneId — the zone our existing 15 NM mob_groups are
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
--   0 — stock size (trash mobs always use this)
--   1 — small bump, barely noticeable
--   2 — clearly "boss-class" (the dungeon default)
--   3 — huge, can clip on tight zones
--
-- This catalog default applies to every dungeon's boss. Per-dungeon
-- override is available via `bossModelSize` on the dungeon entry —
-- set it to 3 on an open zone like Hall of the Gods if you want the
-- boss to read as truly massive, or back to 1 on a cramped arena.
catalog.bossModelSize = 2

-- ============================================================
-- DUNGEONS (3 launch dungeons)
-- ============================================================
-- Difficulty climbs: Whispering Halls (entry) → Echoes of Adoulin
-- (mid) → The Forgotten Bastion (apex). Infamy reward scales steeper
-- than linear — apex pays 5× the entry-tier reward.
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
    -- DUNGEON 1 — THE OUTER BASTION  (Lv99/110/120 trash / Lv135 boss)
    -----------------------------------------------------------
    --
    -- Zone-geometry strategy (lesson from the v1 launch bug):
    --   * warpIn uses the zone's KNOWN-GOOD entry coord (sourced
    --     from the existing mission scripts that already warp here).
    --   * Mobs spawn relative to the PLAYER'S position after the
    --     zone's onZoneIn ran, NOT at fixed catalog coords. The
    --     bossOffset gives an in-front-of-the-player vector; trash
    --     scatters in a ring around the boss.
    --   * This means we don't need to know zone DAT geometry —
    --     wherever the zone actually placed the player IS the arena
    --     center for that run.
    --
    -- Zone history:
    --   v1: Hall of the Gods (251) — rejected (wide-open SoA chamber,
    --       didn't read as "halls").
    --   v2: Monastic Cavern (150) — REJECTED, ~100+ visible native
    --       orcish mobs (15 active mob_groups), the cave is loaded
    --       with patrolling enemies that fight our spawns for AI ticks.
    --   v3 (current): Castle Zvahl Baileys (161) — the Shadow Lord's
    --       outer fortress. Natively heavily populated (270 spawn rows,
    --       39 active mob_groups: Demon Pawns, Dark Knights, Goblin
    --       raiders, Orcish patrols, Quadav/Yagudo squads, Marquis NMs).
    --       Server-wide scrubbed via custom SQL —
    --       modules/custom/sql/dungeon_zvahl_baileys_scrub.sql — so
    --       the zone is empty when our dungeon spawns drop in.
    --
    -- The internal id stays 'whispering_halls' so existing player
    -- CharVars (clear counts, best times) and weekly-hunt objectives
    -- (Dungeon Diver) carry over without resetting.
    {
        id          = 'whispering_halls',
        label       = 'The Outer Bastion',
        description = 'The outer fortress of the dark king. Push east through the demon-haunted halls — the Doom Marquis holds the threshold of the inner keep.',
        zoneId      = xi.zone.CASTLE_ZVAHL_BAILEYS,   -- 161
        zoneName    = 'Castle_Zvahl_Baileys',
        timeLimit   = 900,                            -- 15 minutes
        infamyBase  = 50,
        infamySpeedBonus = 25,

        -- Entry coord sourced from Castle_Zvahl_Baileys/Zone.lua's
        -- onZoneIn default warp (-181.969, -35.542, 19.995, rot 254).
        -- y=-35.5 is the lowest castle level. The zone's 4 cuboid
        -- trigger areas (map 4 teleporter pads) all sit at y=17-19,
        -- so a player staying at y=-35 cannot accidentally fire one
        -- regardless of where the progression axis points them.
        warpIn      = { x = -181.969, y = -35.542, z = 19.995, rot = 254 },

        -- Progression model:
        --   * progressionAxis is a unit vector pointing INTO the dungeon
        --     from the warp-in point (the "depth direction").
        --   * waypoints are tiers placed along that axis at increasing
        --     distance. Each tier has its own count + level + mob pool.
        --   * The boss spawns at the far end of the path (bossDistance).
        --
        -- All mobs are detection-aggro (sight + hearing), so they
        -- engage only when the player approaches. Player walks deeper,
        -- difficulty climbs, then the boss at the end.
        --
        -- Detection range default is ~15 yalms, so the first waypoint
        -- needs to be >=18 yalms from the warpIn so the player doesn't
        -- get insta-aggroed on zone-in.
        -- Tuned 2026-05-28: was way too hard solo. Halved trash counts,
        -- dropped levels by 1 tier so a geared Lv99 can actually clear
        -- the boss within the time limit. Dungeons are a repeatable
        -- Infamy farm, not endgame HNM gating.
        --
        -- First waypoint pushed to 30 yalms (was 18) so the player has
        -- real prep room — Trusts summoned, buffs up, food eaten, none
        -- of it visible to the first mob.
        -- Castle Zvahl Baileys entry is at the WEST side of the
        -- castle (x=-181, z=20). The keep complex extends EAST.
        -- Push waypoints toward +X (deeper into the castle, toward
        -- the keep's threshold). All waypoints stay near z=20 and
        -- y=-35, well clear of the y=17-19 teleporter trigger boxes
        -- at z=45-51 / z=-5--10.
        progressionAxis = { dx = 1.0, dz = 0.0 },
        waypoints =
        {
            { distance = 30, count = 1, level = 99,  scatter = 3.0,
              groups = { 11355, 11357 },
              names  = { 'Lesser Demon' } },
            { distance = 45, count = 1, level = 110, scatter = 3.0,
              groups = { 11359, 11361 },
              names  = { 'Shadowforged Knight' } },
            { distance = 60, count = 1, level = 120, scatter = 3.0,
              groups = { 11358, 11362 },
              names  = { 'Marquis-in-Waiting' } },
        },
        bossDistance = 75,
        bossLevel    = 135,
        bossGroup    = 11364,
        bossName     = 'The Doom Marquis',

        -- Phase 3 — entry-tier mechanics. Lighter touch: a single
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
    -- DUNGEON 2 — THE VOIDWALKER ARENA  (Lv175 trash / Lv225 boss)
    -----------------------------------------------------------
    -- Diorama_Abdhaljs-Ghelsba (43): small, clean arena zone that
    -- the Voidwalker system already uses. No onZoneIn auto-correct,
    -- no trigger areas to worry about, no native mob_groups. Pure
    -- combat space.
    {
        id          = 'voidwalker_arena',
        label       = 'The Voidwalker Arena',
        description = 'A pocket arena suspended between worlds. Press inward — what answers your challenge waits in the dark.',
        zoneId      = xi.zone.DIORAMA_ABDHALJS_GHELSBA,   -- 43
        zoneName    = 'Diorama_Abdhaljs-Ghelsba',
        timeLimit   = 1080,
        infamyBase  = 100,
        infamySpeedBonus = 50,

        warpIn      = { x = 0.0, y = 0.0, z = -10.0, rot = 0 },

        -- Diorama is a smaller arena (~40 yalms across). The 30-yalm
        -- first-waypoint floor still applies, but subsequent waypoints
        -- are more tightly packed than the other dungeons to fit. If
        -- mobs end up clipping into walls in this zone, lower the
        -- bossDistance and tighten the waypoint spacing.
        progressionAxis = { dx = 0.0, dz = 1.0 },
        waypoints =
        {
            { distance = 30, count = 1, level = 120, scatter = 3.0,
              groups = { 11358, 11360 },
              names  = { 'Voidsworn Acolyte' } },
            { distance = 42, count = 2, level = 135, scatter = 3.5,
              groups = { 11362, 11363 },
              names  = { 'Charred Sentinel', 'Glass Stalker' } },
            { distance = 55, count = 2, level = 150, scatter = 3.5,
              groups = { 11364 },
              names  = { 'Withered Knight', 'Ravenous Marauder' } },
        },
        bossDistance = 70,
        bossLevel    = 170,
        bossGroup    = 11365,
        bossName     = 'The Void Maw',

        -- Phase 3 — mid-tier mechanics. Three phases plus a heal at
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
    -- DUNGEON 3 — THE EMPYREAL PARADOX  (Lv140/160/180 trash / Lv200 boss)
    -----------------------------------------------------------
    -- Empyreal Paradox (36): the CoP final-zone, void/sky-sphere
    -- chamber where Promathia is fought. 6 native mob scripts (CoP
    -- finale BC mobs, inert outside the battlefield event). Has
    -- ONE trigger area at (x=538-542, y=-2-0, z=-501--497) that
    -- warps to The Garden of Ru'hmet — small box at the entry
    -- corner. Spawning *inside* it is safe (onTriggerAreaEnter only
    -- fires on boundary crossing), but the progressionAxis must
    -- push AWAY from that box (toward -X / +Z) so the player
    -- doesn't walk back through it on the return loop.
    --
    -- Zone swap 2026-05-29: Cloister of Frost (203) → Empyreal
    -- Paradox (36). Reason: Cloister of Frost felt like a BCNM
    -- arena, not a finale destination. Empyreal Paradox reads as
    -- the cosmic apex it actually is. Internal id stays
    -- 'cloister_of_sorrow' for CharVar / weekly-hunt compat.
    {
        id          = 'cloister_of_sorrow',
        label       = 'The Empyreal Paradox',
        description = 'A void-sphere suspended between worlds. Cut through three rings of the Forgotten; the Paradox itself waits at the center of nothing.',
        zoneId      = xi.zone.EMPYREAL_PARADOX,   -- 36
        zoneName    = 'Empyreal_Paradox',
        timeLimit   = 1200,
        infamyBase  = 250,
        infamySpeedBonus = 100,

        -- Entry coord sourced from Empyreal_Paradox/Zone.lua's onZoneIn
        -- default warp. Lands at the east edge of the chamber. The
        -- Garden-of-Ru'hmet warp trigger sits ON this same coord but
        -- only fires on cross-boundary entry — spawning here is safe
        -- as long as we don't path back into the trigger area.
        warpIn      = { x = 539.0, y = -1.0, z = -500.0, rot = 69 },

        -- Push toward -X (deeper into the chamber, away from the
        -- Garden-of-Ru'hmet warp trigger sitting at x=538-542). The
        -- chamber center is around (0, 0) so going -X keeps the
        -- player heading inward while sliding off the trigger box.
        progressionAxis = { dx = -1.0, dz = 0.0 },
        waypoints =
        {
            { distance = 30, count = 2, level = 140, scatter = 4.0,
              groups = { 11362, 11363 },
              names  = { 'Voidsworn Watcher', 'Hollow Wraith' } },
            { distance = 48, count = 2, level = 160, scatter = 4.0,
              groups = { 11364, 11365 },
              names  = { 'Empyreal Drake', 'Paradox Tyrant' } },
            { distance = 65, count = 3, level = 180, scatter = 4.5,
              groups = { 11366, 11367 },
              names  = { 'Forgotten Inquisitor', 'Banner of the Forgotten', 'Throne Reaver' } },
        },
        bossDistance = 85,
        bossLevel    = 200,
        -- Boss roulette: each run rolls one of these pairs. The
        -- catalog still ships bossGroup / bossName as a singular
        -- fallback for older dungeons; when bossGroups/bossNames is
        -- present and non-empty, the DungeonSystem prefers the plural
        -- form. To pair specific groups with specific names, just keep
        -- the arrays the same length and the indices matched — but
        -- that's optional; in flat form they're picked independently
        -- so the same boss model can show up with different names.
        bossGroup    = 11369,                       -- back-compat default
        bossName     = 'Paradoxon, the Forgotten',  -- back-compat default
        bossGroups   = { 11368, 11369 },            -- Pandemonium Warden / Shinryu
        bossNames    = { 'Paradoxon, the Forgotten', 'Azathoth, the Sundered Crown' },

        -- ============================================================
        -- PHASE 3 — Boss mechanics
        -- ============================================================
        -- HP-threshold phase triggers. Each entry fires once per run
        -- when the boss's HP% drops AT OR BELOW its `hp` threshold,
        -- walked in catalog order so a 75→50→25 chain fires sequentially
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
              message = 'Paradoxon refuses oblivion — its fury is unbound!' },
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
            message = 'TIME ENRAGE — Paradoxon channels the Sundering!',
        },
    },

    -----------------------------------------------------------
    -- DUNGEON 4 — THE ETERNAL THRONE  (Lv200/225/250 trash / Lv275 boss)
    -----------------------------------------------------------
    -- Hall of the Gods (251): the grand SoA congress hall where all
    -- Celestial Avatars once assembled. Vast open nave — no native
    -- mob_groups, no trigger areas, no auto-correct zone scripts.
    -- The wide-open space is intentional for the final encounter:
    -- players need room to manage three waves of adds plus the boss.
    --
    -- warpIn coords: use the zone's default onZoneIn landing
    -- (x=0, y=0, z=0) as the staging point. Adjust if the client
    -- places the player in a different spot — run !pos after entering
    -- and paste the result into warpIn.
    --
    -- Progression note: this dungeon is intentionally the hardest
    -- content on the server. Full BiS (Nyame / Infamy gear + +4 Reforge)
    -- is the expected completion baseline. New players should clear
    -- Dungeons 1–3 first; the Eternal Throne is the prestige run.
    {
        id          = 'eternal_throne',
        label       = 'The Eternal Throne',
        description = 'Where the Celestial Avatars once convened, only silence remains. Fight through the remnants of divine will to reach the seat of eternity itself.',
        zoneId      = xi.zone.HALL_OF_THE_GODS,   -- 251
        zoneName    = 'Hall_of_the_Gods',
        timeLimit   = 1500,                        -- 25 minutes
        infamyBase  = 400,
        infamySpeedBonus = 200,

        -- Verified entry: Hall of the Gods default warp-in. The zone
        -- is a single open chamber with no subdivisions, so any coord
        -- near origin works. Adjust after a live test with !pos.
        warpIn      = { x = 0.0, y = 0.0, z = 0.0, rot = 128 },

        -- Push north (+Z) through the hall. The open geometry means
        -- a long 90-yalm path to the boss is feasible without wall
        -- clipping. Each wave is a full-room engagement.
        progressionAxis = { dx = 0.0, dz = 1.0 },
        waypoints =
        {
            { distance = 30, count = 2, level = 200, scatter = 4.5,
              groups = { 11362, 11363 },
              names  = { 'Throne Sentinel', 'Timeless Watcher' } },
            { distance = 50, count = 2, level = 225, scatter = 5.0,
              groups = { 11364, 11365 },
              names  = { 'Divine Adjudicator', 'Celestial Drake' } },
            { distance = 70, count = 3, level = 250, scatter = 5.0,
              groups = { 11366, 11367, 11368 },
              names  = { 'Avatar\'s Revenant', 'Eternal Inquisitor', 'The Vanquished' } },
        },
        bossDistance = 90,
        bossLevel    = 275,

        -- Boss roulette: Absolute Virtue's ghost or the reborn Shinryu.
        -- Both use the Lv275 stat template — feel free to add a third
        -- entry if you add more HL NM groups later.
        bossGroup    = 11367,                         -- back-compat default
        bossName     = 'Throne of the Eternal',       -- back-compat default
        bossGroups   = { 11367, 11369 },              -- Absolute_Virtue / Shinryu
        bossNames    = { 'Throne of the Eternal', 'The Undying Storm' },

        -- ============================================================
        -- PHASE — 4-phase boss that tests every system in the game
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
              message = 'THE ETERNAL THRONE REFUSES TO FALL — a blinding surge of divine fury!' },
        },
        enrageAfter =
        {
            sec     = 900,    -- 15 minutes into the fight (10 min before overall time limit)
            action  = 'enrage',
            att     = 8000,
            haste   = 300,
            message = 'TIME ENRAGE — The Eternal Throne channels eons of wrath!',
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
    -- Level 275 — Eternal Throne boss tier. Substantially harder than
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
-- Tuned 2026-05-28: was 2.0 (so Lv200 boss = 5× × 2× = 10× base HP,
-- ~150k HP — unkillable in the time limit solo). 1.2 is just enough
-- that the boss feels distinct from the trash without being a sponge.
-- Combined with the level downshifts in each dungeon (apex boss now
-- Lv200 instead of Lv250), a geared Lv99 should be able to clear the
-- entry-tier boss in ~5 min, apex in ~10-12 min.
catalog.bossHpMultiplier = 1.2

-- ============================================================
-- PHASE 1 — PER-RUN AFFIXES
-- ============================================================
-- Every dungeon run rolls 1–2 affixes from this pool. Each affix is a
-- self-contained data row describing:
--   id            unique short string (used in chat / save state)
--   label         display name shown in the entry banner
--   kind          'positive' | 'negative' | 'mixed'  (UI flavour only)
--   description   one-line player-facing explanation
--   applyBoss     optional fn(mob) → applies engine mods to the boss
--                 right after the level template is applied. Cheap
--                 mod-only effects only — anything that needs scripted
--                 AI belongs in a later phase.
--   applyTrash   optional fn(mob) → applied to each trash mob
--   applySession optional fn(sess) → mutates the session table itself
--                 (e.g. tweaks timeLimit). Runs once at session start
--                 BEFORE the timer is armed.
--   rewardMult    multiplier applied to the dungeon's Infamy reward
--                 on clear. Negative affixes give >1.0 (more reward
--                 because the run was harder); positive affixes give
--                 <1.0 (less reward because the run was easier).
--
-- A run rolls catalog.affixCountMin .. catalog.affixCountMax affixes.
-- Final reward multiplier = product of all rolled affixes' rewardMult.
-- e.g. Voracious (1.15) × Mighty (1.20) = 1.38x reward on clear.
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
        description = 'The boss regenerates rapidly — sustain the DPS.',
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
        description = 'The boss never misses — no relying on evasion.',
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
        description = 'Time is short — the arena devours the slow.',
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
        description = 'The boss is reeling — its HP is dramatically reduced.',
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
        description = 'The boss has a glaring weakness — damage taken is doubled.',
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
        description = 'Time bends — the run window stretches 50% longer.',
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
        description = 'The dungeon overflows with riches — Infamy is increased.',
        -- Pure reward modifier. No engine effect, no extra difficulty,
        -- just a happy roll. Rare-feeling because of the steep mult.
        rewardMult  = 1.50,
    },
}

-- ============================================================
-- PHASE 2 — DIFFICULTY TIERS  (Normal / Hard / Mythic)
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
-- MYTHIC AFFIXES  (Tyrannical pool — drawn only at Mythic tier)
-- ============================================================
-- These are nastier than the base pool. They roll only when the
-- chosen tier has mythicAffixPool = true. The base pool still rolls
-- too — Mythic just gets a larger total selection (typically 2–3
-- affixes per run vs 1–2 for Normal/Hard) AND a chance at these.
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
        description = 'Time itself rebels — the window is brutally short.',
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
        description = 'The boss is vastly inflated — bring sustain.',
        applyBoss   = function(mob)
            local hp = mob:getMaxHP()
            mob:setMaxHP(math.floor(hp * 2.0))
            mob:setHP(mob:getMaxHP())
        end,
        rewardMult  = 1.45,
    },
}

-- ============================================================
-- PHASE 4 — META-PROGRESSION
-- ============================================================
-- Three login hooks layered on top of the existing reward path:
--
-- 1. DAILY FEATURED DUNGEON
--    One dungeon per UTC day gets a flat Infamy bonus. Selection is
--    DETERMINISTIC — no server-variable state, no race conditions:
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
-- 3. MYTHIC WEEKLY KEY UI (display only — the gating logic already
--    lives in Phase 2). Main menu now shows "Mythic resets in Xd Yh"
--    next to dungeons whose Mythic key has been burned this week.
-- ============================================================
catalog.featuredBonus   = 0.50  -- +50% Infamy when the dungeon is the day's featured one
catalog.streakStep      = 0.10  -- +10% Infamy per streak point
catalog.streakCap       = 5     -- streak maxes here (so cap mult = 1 + 5*0.10 = 1.50x)
catalog.streakCv        = 'Dungeon_Streak'

-- ============================================================
-- PHASE 6 — PARTY / ALLIANCE SUPPORT
-- ============================================================
-- When a player starts a dungeon, party members in the SAME ZONE
-- (typically GM Home) get warped along and share the run. Leader
-- earns full Infamy; each member alive in the dungeon at clear
-- time gets `memberRewardFactor` of that amount.
--
-- Semantics:
--   * No mid-run join. You're in at warp-in, or you're not in at all.
--   * Leader death  → run ends for everyone (no reward).
--   * Member death  → ONLY that member warps out (no reward); the
--                     run continues for the leader + remaining members.
--   * Boss kill     → success for the leader + every member still
--                     alive in the dungeon zone.
--   * Timeout       → failure for everyone in the zone.
--   * Manual abort  → leader-only; ends the run for everyone.
--
-- Bonus-objective evaluation runs on SHARED session telemetry — if
-- any one player drops below 50% HP, the whole party loses Untouched.
-- That's intentional: group play should feel cooperative, not "let
-- the tank solo while everyone else watches."
catalog.party =
{
    enabled            = true,
    memberRewardFactor = 0.50,   -- members earn 50% of leader's Infamy
    requireSameZone    = true,   -- members must be in the same zone as leader
    maxMembers         = 5,      -- FFXI party caps at 6 (1 leader + 5 members)
}

-- ============================================================
-- PHASE 5 — BONUS OBJECTIVES (skill-expression rewards)
-- ============================================================
-- Evaluated at endDungeon('cleared'). Each objective with a passing
-- `check(sess)` adds its `bonusMult` to the final Infamy formula
-- (additive with featured + streak bonuses, multiplicative with
-- tier × affixes — see the reward chain at the top of endDungeon).
--
-- Objectives are GLOBAL — they apply to every dungeon, every tier.
-- This keeps the system simple to reason about: a player learns the
-- four bonuses once and chases them across all content.
--
-- Each entry:
--   id          stable string id (used in CharVar achievement tags
--               and in the chat-output label)
--   label       short human name shown in the clear banner
--   bonusMult   reward multiplier added (e.g. 0.25 = +25% Infamy)
--   check       function(sess) -> bool — true awards the bonus
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
-- can grow over time — just append to this list.
--
-- All items use raw item IDs. To find the right ID for any item:
--   1. !lookupitem <NAME>  in-game
--   2. Or query: SELECT itemid, name FROM item_basic WHERE name LIKE 'X'
catalog.vendorItems =
{
    -- WEAPONS — Aeonic / Mythic / Relic+3 tier
    { id = 21646, name = 'Naegling',       cost =  500, stats = { 'Sword. Best WS modifier.', 'Aeonic weapon.' } },
    { id = 21632, name = 'Aeneas',         cost =  500, stats = { 'Dagger. Best Rudra Storm.', 'Aeonic weapon.' } },
    { id = 21621, name = 'Daybreak',       cost =  300, stats = { 'Best PLD shield.', 'Empyrean shield.' } },

    -- ACCESSORIES — endgame neck/ring/back
    { id = 26072, name = 'Knobkierrie',    cost =  300, stats = { 'WSD+5%, STR+25.', 'Top WS neck.' } },
    { id = 27928, name = 'Stikini Ring +1',cost =  200, stats = { 'INT+10, MND+10, MEVA+12.', 'Mage ring.' } },

    -- META — the truly exclusive "I'm done" prestige slot
    { id = 13566, name = 'Defending Ring', cost = 1500, stats = { 'Damage Taken -10%.', 'Locks itself once equipped.', 'The grand prize.' } },
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
    -- NYAME — Su5 universal armor (all 22 jobs). Stats from item_mods.
    {
        set  = 'Nyame Universal',
        desc = 'Su5 armor — wearable by all 22 jobs',
        pieces =
        {
            { id = 23761, name = 'Nyame Helm',      cost =  400, stats = { 'DEF:156 HP+91 STR+26 DEX+25 VIT+24 Acc+30 Atk+30 MAcc+40 MAtk+40 MDB+5', 'Magic Dmg+123, Spell Interrupt-700, Phys Dmg Taken-7%', 'Su5 / all 22 jobs' } },
            { id = 23768, name = 'Nyame Mail',      cost =  800, stats = { 'DEF:189 HP+136 STR+35 DEX+24 VIT+35 Acc+30 Atk+30 MAcc+40 MAtk+40 MDB+8', 'Magic Dmg+139, Spell Interrupt-900, Phys Dmg Taken-9%', 'Su5 / all 22 jobs' } },
            { id = 23775, name = 'Nyame Gauntlets', cost =  400, stats = { 'DEF:142 HP+91 STR+17 DEX+42 VIT+39 Acc+30 Atk+30 MAcc+40 MAtk+40 MDB+4', 'Magic Dmg+112, Spell Interrupt-700, Phys Dmg Taken-7%', 'Su5 / all 22 jobs' } },
            { id = 23782, name = 'Nyame Flanchard', cost =  400, stats = { 'DEF:169 HP+114 STR+43 VIT+30 AGI+34 Acc+30 Atk+30 MAcc+40 MAtk+40 MDB+6', 'Magic Dmg+150, Spell Interrupt-800, Phys Dmg Taken-8%', 'Su5 / all 22 jobs' } },
            { id = 23789, name = 'Nyame Sollerets', cost =  400, stats = { 'DEF:122 HP+68 STR+23 DEX+26 AGI+38 Acc+30 Atk+30 MAcc+40 MAtk+40 MDB+5', 'Magic Dmg+150, Spell Interrupt-700, Phys Dmg Taken-7%', 'Su5 / all 22 jobs' } },
        },
    },

    -- HJARRANDI — Odyssey-augmented tank/DPS armor (head + body only)
    {
        set  = 'Hjarrandi Tank',
        desc = 'Odyssey-augmented tank/DPS armor',
        pieces =
        {
            { id = 27637, name = 'Hjarrandi Helm',   cost =  400, stats = { 'Tank head, DPS head.', 'Odyssey augmented.' } },
            { id = 27718, name = 'Hjarrandi Breast', cost =  800, stats = { 'Tank/DPS body.', 'Odyssey augmented.' } },
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
-- These items are sourced from the top scorers across the
-- Armor / Accessory / Weapons NPC catalogs and surfaced here
-- as a premium Infamy-only path. The hand-curated
-- catalog.vendorItems list above is left untouched.
-- Top 20 of 265 unique Gold-tier picks.
catalog.vendorItemsAuto =
{
    { id =  20672, name = 'Ice Brand'                         , cost =  800, stats = { 'CASTER score 1145', 'From Weapons Gold tier (Swords)', 'Jobs: RDM/PLD/BLU' } },
    { id =  22042, name = 'Wizards Rod'                       , cost =  800, stats = { 'CASTER score 1143', 'From Weapons Gold tier (Clubs)', 'Jobs: BLM/RDM/SCH/GEO' } },
    { id =  22055, name = 'Oranyan'                           , cost =  800, stats = { 'CASTER score 1129', 'From Weapons Gold tier (Staves)', 'Jobs: WHM/BLM/RDM/BRD/SMN/SCH/GEO' } },
    { id =  22040, name = 'Daybreak'                          , cost =  800, stats = { 'CASTER score 1116', 'From Weapons Gold tier (Clubs)', 'Jobs: WHM/BLM/RDM/BRD/SMN/SCH/GEO' } },
    { id =  22081, name = 'Raetic Staff +1'                   , cost =  800, stats = { 'CASTER score 1102', 'From Weapons Gold tier (Staves)', 'Jobs: WAR/MNK/WHM/BLM/RDM/BST/BRD/SMN/SCH/GEO' } },
    { id =  22086, name = 'Xoanon'                            , cost =  500, stats = { 'CASTER score 1101', 'From Weapons Gold tier (Staves)', 'Jobs: WAR/MNK/WHM/BLM/RDM/BST/BRD/SMN/SCH/GEO' } },
    { id =  21071, name = 'Cath Palug Hammer'                 , cost =  500, stats = { 'CASTER score 1098', 'From Weapons Gold tier (Clubs)', 'Jobs: WHM/GEO' } },
    { id =  21830, name = 'Drepanum'                          , cost =  500, stats = { 'CASTER score 1086', 'From Weapons Gold tier (Scythes)', 'Jobs: WAR/BLM/DRK/BST' } },
    { id =  22058, name = 'Contemplator +1'                   , cost =  500, stats = { 'CASTER score 1076', 'From Weapons Gold tier (Staves)', 'Jobs: WHM/BLM/RDM/BRD/SMN/SCH/GEO' } },
    { id =  22031, name = 'Maxentius'                         , cost =  500, stats = { 'CASTER score 1071', 'From Weapons Gold tier (Clubs)', 'Jobs: WHM/BLM/RDM/SMN/BLU/SCH/GEO' } },
    { id =  13606, name = 'Judges Cape'                       , cost =  500, stats = { 'DD score 800', 'From Accessory Gold tier (back)', 'Jobs: All' } },
    { id =  26963, name = 'Onca Suit'                         , cost =  350, stats = { 'DD score 746', 'From Armor Gold tier (body)', 'Jobs: WAR/MNK/WHM/BLM/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/SMN/BLU/COR/PUP/DNC/SCH/GEO/RUN' } },
    { id =  23799, name = 'Crepuscular Cloak'                 , cost =  350, stats = { 'CASTER score 654', 'From Armor Gold tier (body)', 'Jobs: WHM/BLM/RDM/DRK/SMN/SCH/GEO' } },
    { id =  25799, name = 'Mallquis Saio +2'                  , cost =  350, stats = { 'CASTER score 513', 'From Armor Gold tier (body)', 'Jobs: BLM/SCH/GEO' } },
    { id =  13505, name = 'Judges Ring'                       , cost =  350, stats = { 'TANK score 500', 'From Accessory Gold tier (ring)', 'Jobs: All' } },
    { id =  25888, name = 'Mallquis Trews +2'                 , cost =  350, stats = { 'CASTER score 499', 'From Armor Gold tier (legs)', 'Jobs: BLM/SCH/GEO' } },
    { id =  24155, name = 'Indomitable Coat'                  , cost =  350, stats = { 'CASTER score 463', 'From Armor Gold tier (body)', 'Jobs: BLM/SMN/SCH/GEO' } },
    { id =  24161, name = 'Indomitable Tonban'                , cost =  250, stats = { 'CASTER score 457', 'From Armor Gold tier (legs)', 'Jobs: BLM/SMN/SCH/GEO' } },
    { id =  24154, name = 'Intrepid Coat'                     , cost =  250, stats = { 'CASTER score 451', 'From Armor Gold tier (body)', 'Jobs: BLM/SMN/SCH/GEO' } },
    { id =  26023, name = 'Sanctity Necklace'                 , cost =  250, stats = { 'CASTER score 252', 'From Accessory Gold tier (neck)', 'Jobs: All' } },
}
-- DOCGEN:INFAMY_AUTO:END

-- Page size for the vendor menu (15-byte budget per line, 6 lines fit
-- comfortably on the customMenu cap).
catalog.vendorPageSize = 6

-- ============================================================
-- +4 REFORGE SETS  (separate browser: Job → Set → Slot)
-- ============================================================
-- 200 Infamy per piece (1000 per full 5-slot set). Stats sourced from
-- BG-Wiki via tools/build_infamy_plus4_catalog.py — regenerate that
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


return catalog
