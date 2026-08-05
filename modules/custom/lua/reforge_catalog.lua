-----------------------------------
-- reforge_catalog.lua
-- Configuration for the Reforge Armor system.
-- Edit this file only - Reforge_System.lua reads it automatically.
--
-- ARCHITECTURE
--   Three NM pools, three currencies, three sets:
--
--                 Source NMs          Currency                  Upgrades
--     AF set      Sky Gods (5)        RF_AF_Marks               Warlock's / etc.
--     Relic set   Unity NMs (5)       RF_Relic_Marks            Vitiation / etc.
--     Empy set    Abyssea NMs (5)     RF_Empy_Marks             Lethargic / etc.
--
--   Each kill awards:
--     * 1 random BASE piece from that set's slice of catalog.pieces
--     * the configured currency for that set
--
--   The Reforge Vendor NPC sells upgrades:
--     base -> +1  costs <set>_Marks (Tier 1 cost)
--     +1   -> +2  costs <set>_Marks (Tier 2 cost)
--     +2   -> +3  costs <set>_Marks (Tier 3 cost)
--
-- POPULATING THE CATALOG
--   Run tools/reforge_catalog_finder.sql in HeidiSQL/mysql to dump item IDs
--   for every reforged piece your DB knows about, then paste rows into the
--   catalog.pieces[...] blocks below. A small RDM sample is included.
-----------------------------------

local catalog = {}

-- =========================================================
-- ZONE / NPC PLACEMENT (mirrors HuntingLeague)
-- =========================================================
-- Reforge hub lives in Diorama Abdhaljs-Ghelsba (zone 43). This is an
-- otherwise-empty diorama, so we get a clean canvas for a dedicated hub.
-- NOTE: zone 43 ships as a level-corrected zone AND without TRUST/AH flags --
-- both are handled outside this file:
--   * scripts/data/level_correction.lua  -> zone 43 added to the FJB exclusion
--     set (endgame NMs/players must NOT be level-synced).
--   * modules/custom/sql/reforge_zone_settings.sql -> OR's TRUST|AH|PET onto
--     zone 43's misc mask (restart-gated).
catalog.huntZoneId   = xi.zone.DIORAMA_ABDHALJS_GHELSBA
catalog.huntZonePath = 'xi.zones.Diorama_Abdhaljs-Ghelsba'
catalog.combatLevel  = 99 -- Difficulty is controlled by the five stat templates.

-- One shared Reforge Vendor + Mark Exchange sit at the hub entrance (origin).
-- The vendor is menu-only (non-blocking), so a single one serves any number of
-- concurrent players. Origin sits ~3 units from verified station-1 ground
-- (X -0.66, Y 0, Z -3.10, "Path"), so this cluster is on walkable terrain.
catalog.vendorPos  = { x = 0.0, y = 0.0, z = 0.0, rot = 128 }

-- --------------------------------------------------------------------------
-- MULTI-STATION SPAWNERS
-- Each station is an independent "NM Spawner" NPC with its OWN mob spawn
-- position and its OWN single-occupancy guard (Reforge_System tracks
-- station.activeMob). This is what lets many parties farm the hub -- even the
-- SAME NM type -- at the same time: station 1 can have Kirin up while station
-- 3 also has Kirin up, because occupancy is per-station, not zone-wide by name.
--
-- Add/remove stations here; Reforge_System.lua loops over this list to build
-- the NPCs and route each spawner to its own mob position. Keep `id` unique.
--
-- COORDINATES: spawnerPos values are LIVE-VERIFIED !pos readings from zone 43
-- (2026-07-07). mobSpawnPos is where the NM actually appears.
--   Station 1 -- short -Z nudge (hub is open; players report this one fine).
--   Station 2 -- was +3 Z into a wall corner; oversized models (Seiryu etc.)
--                stacked the spawner and instantly swung. Spawn toward the
--                open field center instead (~12y).
--   Station 3 -- was +3 Z onto fence posts (untargetable / OOB casts). Spawn
--                toward open ground between stations (~12y).
-- Y kept at verified ground height per station.
-- --------------------------------------------------------------------------
catalog.stations =
{
    -- Station 1 -- hub entrance (Path), beside the vendor/exchange/warp-in.
    { id = 1, spawnerPos = { x =  -0.66, y =  0.00, z =  -3.10, rot = 143 }, mobSpawnPos = { x =  -0.66, y =  0.00, z =  -6.10, rot = 143 } },
    -- Station 2 -- mid field (Grass); NM toward arena center, clear of the wall.
    { id = 2, spawnerPos = { x =  16.64, y = -0.54, z =  52.22, rot = 193 }, mobSpawnPos = { x =   7.00, y = -0.54, z =  45.00, rot = 193 } },
    -- Station 3 -- far field (Path); NM inland of the posts.
    { id = 3, spawnerPos = { x = -26.16, y =  0.28, z =  94.49, rot =   9 }, mobSpawnPos = { x = -18.00, y =  0.28, z =  85.00, rot =   9 } },
}

-- Un-engaged despawn: a popped NM that nobody engages within this many
-- seconds despawns on its own, so an ignored/accidental pop doesn't clog
-- the spawn area (and the duplicate-spawn guard frees up again). The
-- countdown is cancelled the instant a player engages, and re-armed if the
-- NM is abandoned after a fight. Set to 0 to disable. (Mirrors HuntingLeague.)
catalog.unengagedDespawnSecs = 180  -- 3 minutes

-- Seconds after pop before the NM takes enmity on the spawner. Claim still
-- locks immediately so nobody can steal the kill; this buffer stops oversized
-- models (esp. station 2) from DA'ing a caster for ~800 on the spawn tick.
-- Set to 0 to restore instant engage. (Mirrors ApexTrials' delayed enmity.)
catalog.engageGraceSecs = 2.5

-- =========================================================
-- THREE NM POOLS, EACH TIED TO ONE CURRENCY + ONE SET
--
-- setKey is also used to index into catalog.pieces[jobId][setKey].
-- cv is the CharVar that holds the player's mark balance.
-- =========================================================

-- ---------------------------------------------------------
-- DIFFICULTY LADDER
-- All NMs spawn at Lv99. Five legacy-keyed power profiles (150 -> 250)
-- control stats and HP independently of combat level; marks
-- reward scales steeper than linear so the apex NM is worth ~6x
-- the entry NM in the same set.
--
-- Engine notes:
--   xi.mod.HASTE_GEAR is 1024ths of 1%; engine caps total gear
--   haste around 25% (~256), so values past that are wasted unless
--   you want symbolic intent.
--   xi.mod.REGEN is HP per 3-second tick.
--   xi.mod.DOUBLE_ATTACK / TRIPLE_ATTACK are % chance per swing.
--
-- A single edit to a row here retunes every NM at that power step
-- across all three sets. Per-NM overrides are still possible by
-- inlining `mods = { ... }` after `mods = statsFor(N)`.
-- ---------------------------------------------------------
local _LEVEL_TIERS =
{
    [150] = { hpBoost = 5,
              mods = {
                  [xi.mod.DEF] = 520,
                  [xi.mod.ATT] = 2700,
                  -- Reforge is fought at level 99 against augment-era gear.
                  -- The old Hunting League T1 value (270) left entry NMs at
                  -- the 20% hit-rate floor against ordinary geared players.
                  [xi.mod.ACC] = 900,
                  [xi.mod.EVASION] = 140,
                  [xi.mod.MEVA] = 150,
                  [xi.mod.MDEF] = 100,
                  [xi.mod.STR]           = 75,
                  [xi.mod.DEX]           = 75,
                  [xi.mod.HASTE_GEAR]    = 150,
                  [xi.mod.DOUBLE_ATTACK] = 8,
                  [xi.mod.REGEN]         = 12,
              },
    },
    [175] = { hpBoost = 10,
              mods = {
                  [xi.mod.DEF] = 990,
                  [xi.mod.ATT] = 4800,
                  [xi.mod.ACC] = 1200,
                  [xi.mod.EVASION] = 250,
                  [xi.mod.MEVA] = 300,
                  [xi.mod.MDEF] = 240,
                  [xi.mod.STR]           = 200,
                  [xi.mod.DEX]           = 200,
                  [xi.mod.HASTE_GEAR]    = 200,
                  [xi.mod.DOUBLE_ATTACK] = 15,
                  [xi.mod.TRIPLE_ATTACK] = 3,
                  [xi.mod.REGEN]         = 24,
              },
    },
    [200] = { hpBoost = 14,
              mods = {
                  [xi.mod.DEF] = 1430,
                  [xi.mod.ATT] = 7200,
                  [xi.mod.ACC] = 1500,
                  [xi.mod.EVASION] = 350,
                  [xi.mod.MEVA] = 400,
                  [xi.mod.MDEF] = 420,
                  [xi.mod.STR]           = 300,
                  [xi.mod.DEX]           = 300,
                  [xi.mod.HASTE_GEAR]    = 250,
                  [xi.mod.DOUBLE_ATTACK] = 20,
                  [xi.mod.TRIPLE_ATTACK] = 8,
                  [xi.mod.REGEN]         = 40,
              },
    },
    [225] = { hpBoost = 22,
              mods = {
                  [xi.mod.DEF] = 1870,
                  [xi.mod.ATT] = 9600,
                  [xi.mod.ACC] = 2100,
                  [xi.mod.EVASION] = 540,
                  [xi.mod.MEVA] = 600,
                  [xi.mod.MDEF] = 600,
                  [xi.mod.STR]           = 450,
                  [xi.mod.DEX]           = 450,
                  [xi.mod.HASTE_GEAR]    = 280,
                  [xi.mod.DOUBLE_ATTACK] = 23,
                  [xi.mod.TRIPLE_ATTACK] = 10,
                  -- Match Hunting League IV sustain. The mechanics already
                  -- provide the difficulty; legacy 700/tick made this a wall.
                  [xi.mod.REGEN]         = 70,
              },
    },
    [250] = { hpBoost = 30,
              mods = {
                  [xi.mod.DEF] = 2420,
                  [xi.mod.ATT] = 12000,
                  [xi.mod.ACC] = 2400,
                  [xi.mod.EVASION] = 720,
                  [xi.mod.MEVA] = 720,
                  [xi.mod.MDEF] = 840,
                  [xi.mod.STR]           = 600,
                  [xi.mod.DEX]           = 600,
                  [xi.mod.HASTE_GEAR]    = 300,
                  [xi.mod.DOUBLE_ATTACK] = 27,
                  [xi.mod.TRIPLE_ATTACK] = 13,
                  -- Transitional sustain below Apex: enough to discourage
                  -- turtling without demanding Apex-level damage output.
                  [xi.mod.REGEN]         = 100,
              },
    },
}

-- statsFor(level) returns a SHALLOW copy of the level template so
-- inlining further `[xi.mod.X] = ...` after the call in an NM row
-- wouldn't bleed back into the template (template is per-process
-- shared by reference otherwise). The returned table has hpBoost,
-- marks, and a nested mods table - caller spreads into the NM def.
local function statsFor(level)
    local tier = _LEVEL_TIERS[level]
    if not tier then
        error(string.format('reforge_catalog: no level template for Lv%d -- valid: 150/175/200/225/250', level), 2)
    end
    -- mods stays a reference; that's fine because the spawner reads
    -- it and never mutates. Don't rebind/mutate it from the caller.
    return {
        hpBoost = tier.hpBoost,
        mods    = tier.mods,
    }
end

catalog.sources =
{
    af =
    {
        setKey         = 'af',
        label          = 'Sky Gods',
        currencyName   = 'AF Marks',
        currencyShort  = 'AF',
        cv             = 'RF_AF_Marks',
        mobs =
        {
            -- groupId from reforge_nms.sql. minLv/maxLv MUST be set
            -- (engine defaults to lv 255 if missing -> unhittable mob).
            --
            -- Ladder: Genbu (entry) -> Kirin (apex). Mark/stat values
            -- come from the level template; see _LEVEL_TIERS above.
            { name = 'Genbu',  label = 'Genbu  [I]', groupId = 11404, skillList = 277, minLv = 99, maxLv = 99, marks =  60, _t = statsFor(150) },
            { name = 'Suzaku', label = 'Suzaku [II]', groupId = 11403, skillList = 280, minLv = 99, maxLv = 99, marks =  80, _t = statsFor(175) },
            { name = 'Seiryu', label = 'Seiryu [III]', groupId = 11402, skillList = 278, minLv = 99, maxLv = 99, marks = 100, _t = statsFor(200) },
            { name = 'Byakko', label = 'Byakko [IV]', groupId = 11401, skillList = 279, minLv = 99, maxLv = 99, marks = 125, _t = statsFor(225) },
            { name = 'Kirin',  label = 'Kirin  [V]', groupId = 11400, skillList = 281, minLv = 99, maxLv = 99, marks = 150, _t = statsFor(250) },
        },
    },

    relic =
    {
        setKey         = 'relic',
        label          = 'Unity NMs',
        currencyName   = 'Relic Marks',
        currencyShort  = 'Rel',
        cv             = 'RF_Relic_Marks',
        mobs =
        {
            -- Ladder: Bukhis (entry) -> Tinnin (apex). Tinnin retains
            -- apex status from the previous catalog (was 35 marks).
            { name = 'Bukhis',  label = 'Bukhis  [I]', groupId = 11408, skillList = 3000, minLv = 99, maxLv = 99, marks =  60, _t = statsFor(150) },
            { name = 'Khun',    label = 'Khun    [II]', groupId = 11406, skillList = 450, minLv = 99, maxLv = 99, marks =  80, _t = statsFor(175) },
            { name = 'Padfoot', label = 'Padfoot [III]', groupId = 11405, skillList = 226, minLv = 99, maxLv = 99, marks = 100, _t = statsFor(200) },
            { name = 'Glavoid', label = 'Glavoid [IV]', groupId = 11407, skillList = 839, minLv = 99, maxLv = 99, marks = 125, _t = statsFor(225) },
            { name = 'Tinnin',  label = 'Tinnin  [V]', groupId = 11409, skillList = 313, minLv = 99, maxLv = 99, marks = 150, _t = statsFor(250) },
        },
    },

    empy =
    {
        setKey         = 'empy',
        label          = 'Abyssea NMs',
        currencyName   = 'Empy Marks',
        currencyShort  = 'Em',
        cv             = 'RF_Empy_Marks',
        mobs =
        {
            -- Ladder: Aello (entry) -> Hadhayosh (apex). Hadhayosh
            -- (Bahamut Behemoth-type) sits at the top as the most
            -- iconic king-tier Abyssea NM.
            { name = 'Aello',       label = 'Aello       [I]', groupId = 11413, skillList = 471, minLv = 99, maxLv = 99, marks =  60, _t = statsFor(150) },
            { name = 'Iratham',     label = 'Iratham     [II]', groupId = 11411, skillList = 841, minLv = 99, maxLv = 99, marks =  80, _t = statsFor(175) },
            { name = 'Briareus',    label = 'Briareus    [III]', groupId = 11410, skillList = 811, minLv = 99, maxLv = 99, marks = 100, _t = statsFor(200) },
            { name = 'Itzpapalotl', label = 'Itzpapalotl [IV]', groupId = 11412, skillList = 864, minLv = 99, maxLv = 99, marks = 125, _t = statsFor(225) },
            { name = 'Hadhayosh',   label = 'Hadhayosh   [V]', groupId = 11414, skillList = 3001, minLv = 99, maxLv = 99, marks = 150, _t = statsFor(250) },
        },
    },
}

-- Flatten the `_t` template into the mob entry. Done at load time
-- so the spawner code reads `md.hpBoost` / `md.mods` directly without
-- knowing about the indirection. Each NM keeps its OWN `marks` literal
-- (per-NM tunable + visible to the docgen regex), while hpBoost/mods
-- come from the level template for DRY balance edits.
for _, src in pairs(catalog.sources) do
    for _, m in ipairs(src.mobs) do
        if m._t then
            m.hpBoost = m._t.hpBoost
            m.mods    = m._t.mods
            m._t      = nil
        end
    end
end

-- Iteration order for the Spawner menu's category list.
catalog.sourceOrder = { 'af', 'relic', 'empy' }

-- =========================================================
-- UPGRADE COSTS (in each set's own currency)
--   Tune freely. Marks are easy to come by; +3 should be expensive.
-- =========================================================
catalog.upgradeCost =
{
    af    = { plus1 = 300, plus2 = 900, plus3 = 2000 },  -- AF Marks
    relic = { plus1 = 300, plus2 = 900, plus3 = 2000 },  -- Relic Marks
    empy  = { plus1 = 300, plus2 = 900, plus3 = 2000 },  -- Empyrean Marks
}

-- =========================================================
-- JOB LIST  (label used in menus; jobId = xi.job.X)
--   The menu paginates 6 jobs/page; keep labels <= 8 chars.
-- =========================================================
catalog.jobs =
{
    { id = xi.job.WAR, label = 'WAR' },
    { id = xi.job.MNK, label = 'MNK' },
    { id = xi.job.WHM, label = 'WHM' },
    { id = xi.job.BLM, label = 'BLM' },
    { id = xi.job.RDM, label = 'RDM' },
    { id = xi.job.THF, label = 'THF' },
    { id = xi.job.PLD, label = 'PLD' },
    { id = xi.job.DRK, label = 'DRK' },
    { id = xi.job.BST, label = 'BST' },
    { id = xi.job.BRD, label = 'BRD' },
    { id = xi.job.RNG, label = 'RNG' },
    { id = xi.job.SAM, label = 'SAM' },
    { id = xi.job.NIN, label = 'NIN' },
    { id = xi.job.DRG, label = 'DRG' },
    { id = xi.job.SMN, label = 'SMN' },
    { id = xi.job.BLU, label = 'BLU' },
    { id = xi.job.COR, label = 'COR' },
    { id = xi.job.PUP, label = 'PUP' },
    { id = xi.job.DNC, label = 'DNC' },
    { id = xi.job.SCH, label = 'SCH' },
    { id = xi.job.GEO, label = 'GEO' },
    { id = xi.job.RUN, label = 'RUN' },
}

-- =========================================================
-- REFORGED ARMOR CATALOG
--
-- Shape:
--   catalog.pieces[jobId][setKey][slotKey] = { base, plus1, plus2, plus3 }
--
-- setKey  : 'af', 'relic', 'empy'
-- slotKey : 'head', 'body', 'hands', 'legs', 'feet'
-- Each entry: 4 item IDs in tier order (base -> +3). Use 0 for unknown.
--
-- ID ranges (verified against item_basic.sql):
--   AF   base/+1 : 27663-28347  (sequential by job; GEO/RUN bases out-of-order)
--   Rel  base/+1 : 26624-27371  (pairs: base = start+j*2, +1 = start+j*2+1)
--   Empy base/+1 : 26740-27454  (same pair pattern)
--   +2          : 23040-23374   (AF block 23 items, Rel/Empy 22 items per slot)
--   +3          : 23375-23709   (+2 + 335)
-- =========================================================
catalog.pieces = {}

-- ---------- WAR  --  Pummeler's (AF) / Agoge (Relic) / Boii (Empyrean) ----------
catalog.pieces[xi.job.WAR] =
{
    af = -- Pummeler's
    {
        head  = { 27663, 27684, 23040, 23375 },
        body  = { 27807, 27828, 23107, 23442 },
        hands = { 27943, 27964, 23174, 23509 },
        legs  = { 28090, 28111, 23241, 23576 },
        feet  = { 28223, 28244, 23308, 23643 },
    },
    relic = -- Agoge
    {
        head  = { 26624, 26625, 23063, 23398 },
        body  = { 26800, 26801, 23130, 23465 },
        hands = { 26976, 26977, 23197, 23532 },
        legs  = { 27152, 27153, 23264, 23599 },
        feet  = { 27328, 27329, 23331, 23666 },
    },
    empy = -- Boii
    {
        head  = { 26740, 26741, 23085, 23420 },
        body  = { 26898, 26899, 23152, 23487 },
        hands = { 27052, 27053, 23219, 23554 },
        legs  = { 27237, 27238, 23286, 23621 },
        feet  = { 27411, 27412, 23353, 23688 },
    },
}

-- ---------- MNK  --  Anchorite's (AF) / Hesychast's (Relic) / Bhikku (Empyrean) ----------
catalog.pieces[xi.job.MNK] =
{
    af = -- Anchorite's
    {
        head  = { 27664, 27685, 23041, 23376 },
        body  = { 27808, 27829, 23108, 23443 },
        hands = { 27944, 27965, 23175, 23510 },
        legs  = { 28091, 28112, 23242, 23577 },
        feet  = { 28224, 28245, 23309, 23644 },
    },
    relic = -- Hesychast's
    {
        head  = { 26626, 26627, 23064, 23399 },
        body  = { 26802, 26803, 23131, 23466 },
        hands = { 26978, 26979, 23198, 23533 },
        legs  = { 27154, 27155, 23265, 23600 },
        feet  = { 27330, 27331, 23332, 23667 },
    },
    empy = -- Bhikku
    {
        head  = { 26742, 26743, 23086, 23421 },
        body  = { 26900, 26901, 23153, 23488 },
        hands = { 27054, 27055, 23220, 23555 },
        legs  = { 27239, 27240, 23287, 23622 },
        feet  = { 27413, 27414, 23354, 23689 },
    },
}

-- ---------- WHM  --  Theophany (AF) / Piety (Relic) / Ebers (Empyrean) ----------
catalog.pieces[xi.job.WHM] =
{
    af = -- Theophany
    {
        head  = { 27665, 27686, 23042, 23377 },
        body  = { 27809, 27830, 23109, 23444 },
        hands = { 27945, 27966, 23176, 23511 },
        legs  = { 28092, 28113, 23243, 23578 },
        feet  = { 28225, 28246, 23310, 23645 },
    },
    relic = -- Piety
    {
        head  = { 26628, 26629, 23065, 23400 },
        body  = { 26804, 26805, 23132, 23467 },
        hands = { 26980, 26981, 23199, 23534 },
        legs  = { 27156, 27157, 23266, 23601 },
        feet  = { 27332, 27333, 23333, 23668 },
    },
    empy = -- Ebers
    {
        head  = { 26744, 26745, 23087, 23422 },
        body  = { 26902, 26903, 23154, 23489 },
        hands = { 27056, 27057, 23221, 23556 },
        legs  = { 27241, 27242, 23288, 23623 },
        feet  = { 27415, 27416, 23355, 23690 },
    },
}

-- ---------- BLM  --  Spaekona's (AF) / Archmage's (Relic) / Wicce (Empyrean) ----------
catalog.pieces[xi.job.BLM] =
{
    af = -- Spaekona's
    {
        head  = { 27666, 27687, 23043, 23378 },
        body  = { 27810, 27831, 23110, 23445 },
        hands = { 27946, 27967, 23177, 23512 },
        legs  = { 28093, 28114, 23244, 23579 },
        feet  = { 28226, 28247, 23311, 23646 },
    },
    relic = -- Archmage's
    {
        head  = { 26630, 26631, 23066, 23401 },
        body  = { 26806, 26807, 23133, 23468 },
        hands = { 26982, 26983, 23200, 23535 },
        legs  = { 27158, 27159, 23267, 23602 },
        feet  = { 27334, 27335, 23334, 23669 },
    },
    empy = -- Wicce
    {
        head  = { 26746, 26747, 23088, 23423 },
        body  = { 26904, 26905, 23155, 23490 },
        hands = { 27058, 27059, 23222, 23557 },
        legs  = { 27243, 27244, 23289, 23624 },
        feet  = { 27417, 27418, 23356, 23691 },
    },
}

-- ---------- RDM  --  Atrophy (AF) / Vitiation (Relic) / Lethargic (Empyrean) ----------
catalog.pieces[xi.job.RDM] =
{
    af = -- Atrophy
    {
        head  = { 27667, 27688, 23044, 23379 },
        body  = { 27811, 27832, 23111, 23446 },
        hands = { 27947, 27968, 23178, 23513 },
        legs  = { 28094, 28115, 23245, 23580 },
        feet  = { 28227, 28248, 23312, 23647 },
    },
    relic = -- Vitiation
    {
        head  = { 26632, 26633, 23067, 23402 },
        body  = { 26808, 26809, 23134, 23469 },
        hands = { 26984, 26985, 23201, 23536 },
        legs  = { 27160, 27161, 23268, 23603 },
        feet  = { 27336, 27337, 23335, 23670 },
    },
    empy = -- Lethargic
    {
        head  = { 26748, 26749, 23089, 23424 },
        body  = { 26906, 26907, 23156, 23491 },
        hands = { 27060, 27061, 23223, 23558 },
        legs  = { 27245, 27246, 23290, 23625 },
        feet  = { 27419, 27420, 23357, 23692 },
    },
}

-- ---------- THF  --  Pillager's (AF) / Plunderer's (Relic) / Skulker's (Empyrean) ----------
catalog.pieces[xi.job.THF] =
{
    af = -- Pillager's
    {
        head  = { 27668, 27689, 23045, 23380 },
        body  = { 27812, 27833, 23112, 23447 },
        hands = { 27948, 27969, 23179, 23514 },
        legs  = { 28095, 28116, 23246, 23581 },
        feet  = { 28228, 28249, 23313, 23648 },
    },
    relic = -- Plunderer's
    {
        head  = { 26634, 26635, 23068, 23403 },
        body  = { 26810, 26811, 23135, 23470 },
        hands = { 26986, 26987, 23202, 23537 },
        legs  = { 27162, 27163, 23269, 23604 },
        feet  = { 27338, 27339, 23336, 23671 },
    },
    empy = -- Skulker's
    {
        head  = { 26750, 26751, 23090, 23425 },
        body  = { 26908, 26909, 23157, 23492 },
        hands = { 27062, 27063, 23224, 23559 },
        legs  = { 27247, 27248, 23291, 23626 },
        feet  = { 27421, 27422, 23358, 23693 },
    },
}

-- ---------- PLD  --  Reverence (AF) / Caballarius (Relic) / Chevalier's (Empyrean) ----------
catalog.pieces[xi.job.PLD] =
{
    af = -- Reverence
    {
        head  = { 27669, 27690, 23046, 23381 },
        body  = { 27813, 27834, 23113, 23448 },
        hands = { 27949, 27970, 23180, 23515 },
        legs  = { 28096, 28117, 23247, 23582 },
        feet  = { 28229, 28250, 23314, 23649 },
    },
    relic = -- Caballarius
    {
        head  = { 26636, 26637, 23069, 23404 },
        body  = { 26812, 26813, 23136, 23471 },
        hands = { 26988, 26989, 23203, 23538 },
        legs  = { 27164, 27165, 23270, 23605 },
        feet  = { 27340, 27341, 23337, 23672 },
    },
    empy = -- Chevalier's
    {
        head  = { 26752, 26753, 23091, 23426 },
        body  = { 26910, 26911, 23158, 23493 },
        hands = { 27064, 27065, 23225, 23560 },
        legs  = { 27249, 27250, 23292, 23627 },
        feet  = { 27423, 27424, 23359, 23694 },
    },
}

-- ---------- DRK  --  Ignominy (AF) / Fallen's (Relic) / Heathen's (Empyrean) ----------
catalog.pieces[xi.job.DRK] =
{
    af = -- Ignominy
    {
        head  = { 27670, 27691, 23047, 23382 },
        body  = { 27814, 27835, 23114, 23449 },
        hands = { 27950, 27971, 23181, 23516 },
        legs  = { 28097, 28118, 23248, 23583 },
        feet  = { 28230, 28251, 23315, 23650 },
    },
    relic = -- Fallen's
    {
        head  = { 26638, 26639, 23070, 23405 },
        body  = { 26814, 26815, 23137, 23472 },
        hands = { 26990, 26991, 23204, 23539 },
        legs  = { 27166, 27167, 23271, 23606 },
        feet  = { 27342, 27343, 23338, 23673 },
    },
    empy = -- Heathen's
    {
        head  = { 26754, 26755, 23092, 23427 },
        body  = { 26912, 26913, 23159, 23494 },
        hands = { 27066, 27067, 23226, 23561 },
        legs  = { 27251, 27252, 23293, 23628 },
        feet  = { 27425, 27426, 23360, 23695 },
    },
}

-- ---------- BST  --  Totemic (AF) / Ankusa (Relic) / Nukumi (Empyrean) ----------
catalog.pieces[xi.job.BST] =
{
    af = -- Totemic
    {
        head  = { 27671, 27692, 23048, 23383 },
        body  = { 27815, 27836, 23115, 23450 },
        hands = { 27951, 27972, 23182, 23517 },
        legs  = { 28098, 28119, 23249, 23584 },
        feet  = { 28231, 28252, 23316, 23651 },
    },
    relic = -- Ankusa
    {
        head  = { 26640, 26641, 23071, 23406 },
        body  = { 26816, 26817, 23138, 23473 },
        hands = { 26992, 26993, 23205, 23540 },
        legs  = { 27168, 27169, 23272, 23607 },
        feet  = { 27344, 27345, 23339, 23674 },
    },
    empy = -- Nukumi
    {
        head  = { 26756, 26757, 23093, 23428 },
        body  = { 26914, 26915, 23160, 23495 },
        hands = { 27068, 27069, 23227, 23562 },
        legs  = { 27253, 27254, 23294, 23629 },
        feet  = { 27427, 27428, 23361, 23696 },
    },
}

-- ---------- BRD  --  Brioso (AF) / Bihu (Relic) / Fili (Empyrean) ----------
catalog.pieces[xi.job.BRD] =
{
    af = -- Brioso
    {
        head  = { 27672, 27693, 23049, 23384 },
        body  = { 27816, 27837, 23116, 23451 },
        hands = { 27952, 27973, 23183, 23518 },
        legs  = { 28099, 28120, 23250, 23585 },
        feet  = { 28232, 28253, 23317, 23652 },
    },
    relic = -- Bihu
    {
        head  = { 26642, 26643, 23072, 23407 },
        body  = { 26818, 26819, 23139, 23474 },
        hands = { 26994, 26995, 23206, 23541 },
        legs  = { 27170, 27171, 23273, 23608 },
        feet  = { 27346, 27347, 23340, 23675 },
    },
    empy = -- Fili
    {
        head  = { 26758, 26759, 23094, 23429 },
        body  = { 26916, 26917, 23161, 23496 },
        hands = { 27070, 27071, 23228, 23563 },
        legs  = { 27255, 27256, 23295, 23630 },
        feet  = { 27429, 27430, 23362, 23697 },
    },
}

-- ---------- RNG  --  Orion (AF) / Arcadian (Relic) / Amini (Empyrean) ----------
catalog.pieces[xi.job.RNG] =
{
    af = -- Orion
    {
        head  = { 27673, 27694, 23050, 23385 },
        body  = { 27817, 27838, 23117, 23452 },
        hands = { 27953, 27974, 23184, 23519 },
        legs  = { 28100, 28121, 23251, 23586 },
        feet  = { 28233, 28254, 23318, 23653 },
    },
    relic = -- Arcadian
    {
        head  = { 26644, 26645, 23073, 23408 },
        body  = { 26820, 26821, 23140, 23475 },
        hands = { 26996, 26997, 23207, 23542 },
        legs  = { 27172, 27173, 23274, 23609 },
        feet  = { 27348, 27349, 23341, 23676 },
    },
    empy = -- Amini
    {
        head  = { 26760, 26761, 23095, 23430 },
        body  = { 26918, 26919, 23162, 23497 },
        hands = { 27072, 27073, 23229, 23564 },
        legs  = { 27257, 27258, 23296, 23631 },
        feet  = { 27431, 27432, 23363, 23698 },
    },
}

-- ---------- SAM  --  Wakido (AF) / Sakonji (Relic) / Kasuga (Empyrean) ----------
catalog.pieces[xi.job.SAM] =
{
    af = -- Wakido
    {
        head  = { 27674, 27695, 23051, 23386 },
        body  = { 27818, 27839, 23118, 23453 },
        hands = { 27954, 27975, 23185, 23520 },
        legs  = { 28101, 28122, 23252, 23587 },
        feet  = { 28234, 28255, 23319, 23654 },
    },
    relic = -- Sakonji
    {
        head  = { 26646, 26647, 23074, 23409 },
        body  = { 26822, 26823, 23141, 23476 },
        hands = { 26998, 26999, 23208, 23543 },
        legs  = { 27174, 27175, 23275, 23610 },
        feet  = { 27350, 27351, 23342, 23677 },
    },
    empy = -- Kasuga
    {
        head  = { 26762, 26763, 23096, 23431 },
        body  = { 26920, 26921, 23163, 23498 },
        hands = { 27074, 27075, 23230, 23565 },
        legs  = { 27259, 27260, 23297, 23632 },
        feet  = { 27433, 27434, 23364, 23699 },
    },
}

-- ---------- NIN  --  Hachiya (AF) / Mochizuki (Relic) / Hattori (Empyrean) ----------
catalog.pieces[xi.job.NIN] =
{
    af = -- Hachiya
    {
        head  = { 27675, 27696, 23052, 23387 },
        body  = { 27819, 27840, 23119, 23454 },
        hands = { 27955, 27976, 23186, 23521 },
        legs  = { 28102, 28123, 23253, 23588 },
        feet  = { 28235, 28256, 23320, 23655 },
    },
    relic = -- Mochizuki
    {
        head  = { 26648, 26649, 23075, 23410 },
        body  = { 26824, 26825, 23142, 23477 },
        hands = { 27000, 27001, 23209, 23544 },
        legs  = { 27176, 27177, 23276, 23611 },
        feet  = { 27352, 27353, 23343, 23678 },
    },
    empy = -- Hattori
    {
        head  = { 26764, 26765, 23097, 23432 },
        body  = { 26922, 26923, 23164, 23499 },
        hands = { 27076, 27077, 23231, 23566 },
        legs  = { 27261, 27262, 23298, 23633 },
        feet  = { 27435, 27436, 23365, 23700 },
    },
}

-- ---------- DRG  --  Vishap (AF) / Pteroslaver (Relic) / Peltast's (Empyrean) ----------
catalog.pieces[xi.job.DRG] =
{
    af = -- Vishap
    {
        head  = { 27676, 27697, 23053, 23388 },
        body  = { 27820, 27841, 23120, 23455 },
        hands = { 27956, 27977, 23187, 23522 },
        legs  = { 28103, 28124, 23254, 23589 },
        feet  = { 28236, 28257, 23321, 23656 },
    },
    relic = -- Pteroslaver
    {
        head  = { 26650, 26651, 23076, 23411 },
        body  = { 26826, 26827, 23143, 23478 },
        hands = { 27002, 27003, 23210, 23545 },
        legs  = { 27178, 27179, 23277, 23612 },
        feet  = { 27354, 27355, 23344, 23679 },
    },
    empy = -- Peltast's
    {
        head  = { 26766, 26767, 23098, 23433 },
        body  = { 26924, 26925, 23165, 23500 },
        hands = { 27078, 27079, 23232, 23567 },
        legs  = { 27263, 27264, 23299, 23634 },
        feet  = { 27437, 27438, 23366, 23701 },
    },
}

-- ---------- SMN  --  Convoker's (AF) / Glyphic (Relic) / Beckoner's (Empyrean) ----------
catalog.pieces[xi.job.SMN] =
{
    af = -- Convoker's
    {
        head  = { 27677, 27698, 23054, 23389 },
        body  = { 27821, 27842, 23121, 23456 },
        hands = { 27957, 27978, 23188, 23523 },
        legs  = { 28104, 28125, 23255, 23590 },
        feet  = { 28237, 28258, 23322, 23657 },
    },
    relic = -- Glyphic
    {
        head  = { 26652, 26653, 23077, 23412 },
        body  = { 26828, 26829, 23144, 23479 },
        hands = { 27004, 27005, 23211, 23546 },
        legs  = { 27180, 27181, 23278, 23613 },
        feet  = { 27356, 27357, 23345, 23680 },
    },
    empy = -- Beckoner's
    {
        head  = { 26768, 26769, 23099, 23434 },
        body  = { 26926, 26927, 23166, 23501 },
        hands = { 27080, 27081, 23233, 23568 },
        legs  = { 27265, 27266, 23300, 23635 },
        feet  = { 27439, 27440, 23367, 23702 },
    },
}

-- ---------- BLU  --  Assimilator's (AF) / Luhlaza (Relic) / Hashishin (Empyrean) ----------
catalog.pieces[xi.job.BLU] =
{
    af = -- Assimilator's
    {
        head  = { 27678, 27699, 23055, 23390 },
        body  = { 27822, 27843, 23122, 23457 },
        hands = { 27958, 27979, 23189, 23524 },
        legs  = { 28105, 28126, 23256, 23591 },
        feet  = { 28238, 28259, 23323, 23658 },
    },
    relic = -- Luhlaza
    {
        head  = { 26654, 26655, 23078, 23413 },
        body  = { 26830, 26831, 23145, 23480 },
        hands = { 27006, 27007, 23212, 23547 },
        legs  = { 27182, 27183, 23279, 23614 },
        feet  = { 27358, 27359, 23346, 23681 },
    },
    empy = -- Hashishin
    {
        head  = { 26770, 26771, 23100, 23435 },
        body  = { 26928, 26929, 23167, 23502 },
        hands = { 27082, 27083, 23234, 23569 },
        legs  = { 27267, 27268, 23301, 23636 },
        feet  = { 27441, 27442, 23368, 23703 },
    },
}

-- ---------- COR  --  Laksamana's (AF) / Lanun (Relic) / Chasseur's (Empyrean) ----------
catalog.pieces[xi.job.COR] =
{
    af = -- Laksamana's
    {
        head  = { 27679, 27700, 23056, 23391 },
        body  = { 27823, 27844, 23123, 23458 },
        hands = { 27959, 27980, 23190, 23525 },
        legs  = { 28106, 28127, 23257, 23592 },
        feet  = { 28239, 28260, 23324, 23659 },
    },
    relic = -- Lanun
    {
        head  = { 26656, 26657, 23079, 23414 },
        body  = { 26832, 26833, 23146, 23481 },
        hands = { 27008, 27009, 23213, 23548 },
        legs  = { 27184, 27185, 23280, 23615 },
        feet  = { 27360, 27361, 23347, 23682 },
    },
    empy = -- Chasseur's
    {
        head  = { 26772, 26773, 23101, 23436 },
        body  = { 26930, 26931, 23168, 23503 },
        hands = { 27084, 27085, 23235, 23570 },
        legs  = { 27269, 27270, 23302, 23637 },
        feet  = { 27443, 27444, 23369, 23704 },
    },
}

-- ---------- PUP  --  Foire (AF) / Pitre (Relic) / Karagoz (Empyrean) ----------
catalog.pieces[xi.job.PUP] =
{
    af = -- Foire
    {
        head  = { 27680, 27701, 23057, 23392 },
        body  = { 27824, 27845, 23124, 23459 },
        hands = { 27960, 27981, 23191, 23526 },
        legs  = { 28107, 28128, 23258, 23593 },
        feet  = { 28240, 28261, 23325, 23660 },
    },
    relic = -- Pitre
    {
        head  = { 26658, 26659, 23080, 23415 },
        body  = { 26834, 26835, 23147, 23482 },
        hands = { 27010, 27011, 23214, 23549 },
        legs  = { 27186, 27187, 23281, 23616 },
        feet  = { 27362, 27363, 23348, 23683 },
    },
    empy = -- Karagoz
    {
        head  = { 26774, 26775, 23102, 23437 },
        body  = { 26932, 26933, 23169, 23504 },
        hands = { 27086, 27087, 23236, 23571 },
        legs  = { 27271, 27272, 23303, 23638 },
        feet  = { 27445, 27446, 23370, 23705 },
    },
}

-- ---------- DNC  --  Maxixi (AF) / Horos (Relic) / Maculele (Empyrean) ----------
-- AF uses male variant (27681); female variant (27682) omitted.
catalog.pieces[xi.job.DNC] =
{
    af = -- Maxixi
    {
        head  = { 27681, 27702, 23058, 23393 },
        body  = { 27825, 27846, 23125, 23460 },
        hands = { 27961, 27982, 23192, 23527 },
        legs  = { 28108, 28129, 23259, 23594 },
        feet  = { 28241, 28262, 23326, 23661 },
    },
    relic = -- Horos
    {
        head  = { 26660, 26661, 23081, 23416 },
        body  = { 26836, 26837, 23148, 23483 },
        hands = { 27012, 27013, 23215, 23550 },
        legs  = { 27188, 27189, 23282, 23617 },
        feet  = { 27364, 27365, 23349, 23684 },
    },
    empy = -- Maculele
    {
        head  = { 26776, 26777, 23103, 23438 },
        body  = { 26934, 26935, 23170, 23505 },
        hands = { 27088, 27089, 23237, 23572 },
        legs  = { 27273, 27274, 23304, 23639 },
        feet  = { 27447, 27448, 23371, 23706 },
    },
}

-- ---------- SCH  --  Academic's (AF) / Pedagogy (Relic) / Arbatel (Empyrean) ----------
-- AF block offset 20 (DNC female occupies offset 19, shifting SCH/GEO/RUN by 1).
catalog.pieces[xi.job.SCH] =
{
    af = -- Academic's
    {
        head  = { 27683, 27704, 23060, 23395 },
        body  = { 27827, 27848, 23127, 23462 },
        hands = { 27963, 27984, 23194, 23529 },
        legs  = { 28110, 28131, 23261, 23596 },
        feet  = { 28243, 28264, 23328, 23663 },
    },
    relic = -- Pedagogy
    {
        head  = { 26662, 26663, 23082, 23417 },
        body  = { 26838, 26839, 23149, 23484 },
        hands = { 27014, 27015, 23216, 23551 },
        legs  = { 27190, 27191, 23283, 23618 },
        feet  = { 27366, 27367, 23350, 23685 },
    },
    empy = -- Arbatel
    {
        head  = { 26778, 26779, 23104, 23439 },
        body  = { 26936, 26937, 23171, 23506 },
        hands = { 27090, 27091, 23238, 23573 },
        legs  = { 27275, 27276, 23305, 23640 },
        feet  = { 27449, 27450, 23372, 23707 },
    },
}

-- ---------- GEO  --  Geomancy (AF) / Bagua (Relic) / Azimuth (Empyrean) ----------
-- AF base IDs are out-of-sequence (added later): 27786/27926/28066/28206/28346.
-- AF +1 IDs are sequential with the rest of the block.
catalog.pieces[xi.job.GEO] =
{
    af = -- Geomancy
    {
        head  = { 27786, 27705, 23061, 23396 },
        body  = { 27926, 27849, 23128, 23463 },
        hands = { 28066, 27985, 23195, 23530 },
        legs  = { 28206, 28132, 23262, 23597 },
        feet  = { 28346, 28265, 23329, 23664 },
    },
    relic = -- Bagua
    {
        head  = { 26664, 26665, 23083, 23418 },
        body  = { 26840, 26841, 23150, 23485 },
        hands = { 27016, 27017, 23217, 23552 },
        legs  = { 27192, 27193, 23284, 23619 },
        feet  = { 27368, 27369, 23351, 23686 },
    },
    empy = -- Azimuth
    {
        head  = { 26780, 26781, 23105, 23440 },
        body  = { 26938, 26939, 23172, 23507 },
        hands = { 27092, 27093, 23239, 23574 },
        legs  = { 27277, 27278, 23306, 23641 },
        feet  = { 27451, 27452, 23373, 23708 },
    },
}

-- ---------- RUN  --  Runeist (AF) / Futhark (Relic) / Erilaz (Empyrean) ----------
-- AF base IDs are out-of-sequence (added later): 27787/27927/28067/28207/28347.
-- AF +1 IDs are sequential with the rest of the block.
catalog.pieces[xi.job.RUN] =
{
    af = -- Runeist
    {
        head  = { 27787, 27706, 23062, 23397 },
        body  = { 27927, 27850, 23129, 23464 },
        hands = { 28067, 27986, 23196, 23531 },
        legs  = { 28207, 28133, 23263, 23598 },
        feet  = { 28347, 28266, 23330, 23665 },
    },
    relic = -- Futhark
    {
        head  = { 26666, 26667, 23084, 23419 },
        body  = { 26842, 26843, 23151, 23486 },
        hands = { 27018, 27019, 23218, 23553 },
        legs  = { 27194, 27195, 23285, 23620 },
        feet  = { 27370, 27371, 23352, 23687 },
    },
    empy = -- Erilaz
    {
        head  = { 26782, 26783, 23106, 23441 },
        body  = { 26940, 26941, 23173, 23508 },
        hands = { 27094, 27095, 23240, 23575 },
        legs  = { 27279, 27280, 23307, 23642 },
        feet  = { 27453, 27454, 23374, 23709 },
    },
}

-- =========================================================
-- HARDCORE MECHANICS CONFIGS  (mob_mechanics_library.lua)
--
-- Keyed by groupId so the spawner can look them up in O(1) after spawn().
-- Each NM tier has a DISTINCT identity escalating in complexity and threat.
-- addZoneId MUST equal catalog.huntZoneId (xi.zone.DIORAMA_ABDHALJS_GHELSBA).
-- addGroupId must be a groupId already in this system (entry-tier NMs used
-- as minion adds so their AI/stats are already defined in the mob_groups rows).
--
-- Power-step identities (all combat level 99):
--   I   (entry)   - light anti-turtle drain
--   II  (mid-low) - stance dance + terror CC
--   III (mid)     - AoE + drain + nuke phase
--   IV  (hard)    - stance + CC + light drain + fury/dispel phases + doom
--   V   (bridge)  - full suite, but gentler sustain than Apex progression
--
-- DMGPHYS/DMGMAGIC cap at -5000 per library rules (=-50% taken).
-- =========================================================
catalog.mechCfgs = {}

-- -------------------------
-- AF set (Sky Gods) groupIds: Genbu=11404, Suzaku=11403, Seiryu=11402, Byakko=11401, Kirin=11400
-- -------------------------

-- Genbu entry - light anti-turtle drain only
catalog.mechCfgs[11404] = {
    name  = 'Genbu',
    drain = { periodSec = 10, healPct = 0.25 },
}

-- Suzaku [Lv175] - stance dance: fire phases, terror roar
catalog.mechCfgs[11403] = {
    name   = 'Suzaku',
    stance = { startHpp = 100, periodSec = 18,
        stances = {
            { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0    }, msg = 'is wreathed in vermilion flames -- use magic!' },
            { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'sheds the flames -- use steel!' },
        }
    },
    cc = { periodSec = 22, effect = xi.effect.TERROR, dur = 5, msg = 'unleashes a terrifying Phoenix Cry!' },
}

-- Seiryu [Lv200] - mid-tier: AoE + drain + phase nuke
catalog.mechCfgs[11402] = {
    name  = 'Seiryu',
    aoe   = { periodSec = 12, dmgPct = 22, msg = 'surges with draconic energy!' },
    drain = { periodSec = 9,  healPct = 0.25 },
    phases = {
        { hp = 40, action = 'nuke',  dmgPct = 38, msg = 'channels Azure Dragon\'s final breath!' },
        { hp = 20, action = 'fury',  att = 3500, haste = 110, msg = 'enters Azure Dragon Fury!' },
    },
}

-- Byakko [Lv225] - hard: stance + CC + drain + fury + dispel + doom
catalog.mechCfgs[11401] = {
    name   = 'Byakko',
    stance = { startHpp = 100, periodSec = 16,
        stances = {
            { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0    }, msg = 'bristles with White Tiger energy -- use magic!' },
            { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'deflects all magic -- use steel!' },
        }
    },
    cc    = { periodSec = 20, effect = xi.effect.TERROR, dur = 6, msg = 'unleashes a blinding White Roar!' },
    drain = { periodSec = 10, healPct = 0.5 },
    phases = {
        { hp = 40, action = 'fury',   att = 4000, haste = 130, msg = 'enters White Tiger Fury!' },
        { hp = 25, action = 'dispel', count = 4, msg = 'strips your enhancements with Byakko\'s Rage!' },
    },
    doom = { startHpp = 18, dur = 28, msg = 'marks you with the Tiger\'s Curse!' },
}

-- Kirin [Lv250] - pre-Apex bridge: full suite, forgiving sustain/clock
catalog.mechCfgs[11400] = {
    name   = 'Kirin',
    enrage = { sec = 240, att = 5000, haste = 200, msg = 'Kirin\'s patience shatters -- ENRAGE!' },
    stance = { startHpp = 100, periodSec = 15,
        stances = {
            { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0    }, msg = 'is hardened against weapons -- switch to magic!' },
            { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'refracts all magic -- switch to weapons!' },
        }
    },
    aoe   = { periodSec = 11, dmgPct = 24, msg = 'unleashes Heaven\'s Wrath across the battlefield!' },
    cc    = { periodSec = 19, effect = xi.effect.TERROR, dur = 7, msg = 'emanates a divine aura of terror!' },
    drain = { periodSec = 10, healPct = 0.75 },
    phases = {
        { hp = 60, action = 'fury',   att = 3500, haste = 120, msg = 'channels divine fury!' },
        { hp = 25, action = 'nuke',   dmgPct = 42, msg = 'unleashes Heavenly Judgment!' },
        { hp = 15, action = 'dispel', count = 5, msg = 'strips you bare with Five-God Seal!' },
        { hp = 10, action = 'enrage', att = 8000, haste = 250, msg = 'ascends beyond mortal limits!' },
    },
    doom = { startHpp = 12, dur = 25, msg = 'brands you with the Seal of Heaven -- survive!' },
}

-- -------------------------
-- Relic set (Unity NMs) groupIds: Bukhis=11408, Khun=11406, Padfoot=11405, Glavoid=11407, Tinnin=11409
-- -------------------------

-- Bukhis entry - light anti-turtle drain only
catalog.mechCfgs[11408] = {
    name  = 'Bukhis',
    drain = { periodSec = 10, healPct = 0.25 },
}

-- Khun [Lv175] - stance dance: sonic phases + terror
catalog.mechCfgs[11406] = {
    name   = 'Khun',
    stance = { startHpp = 100, periodSec = 18,
        stances = {
            { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0    }, msg = 'hardens its carapace -- use magic!' },
            { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'crackles with Thunder Shell -- use steel!' },
        }
    },
    cc = { periodSec = 22, effect = xi.effect.TERROR, dur = 5, msg = 'emits a Sonic Roar of pure terror!' },
}

-- Padfoot [Lv200] - mid-tier: AoE + drain + nuke
catalog.mechCfgs[11405] = {
    name  = 'Padfoot',
    aoe   = { periodSec = 12, dmgPct = 22, msg = 'unleashes Spectral Howl across the area!' },
    drain = { periodSec = 9,  healPct = 0.25 },
    phases = {
        { hp = 40, action = 'nuke',  dmgPct = 38, msg = 'channels Dark Maw!' },
        { hp = 20, action = 'fury',  att = 3500, haste = 110, msg = 'enters Spectral Fury!' },
    },
}

-- Glavoid [Lv225] - hard: stance + CC + drain + fury + dispel + doom
catalog.mechCfgs[11407] = {
    name   = 'Glavoid',
    stance = { startHpp = 100, periodSec = 16,
        stances = {
            { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0    }, msg = 'burrows into the earth -- it deflects weapons! Use magic!' },
            { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'surfaces coated in Null Slime -- magic slides off! Use steel!' },
        }
    },
    cc    = { periodSec = 20, effect = xi.effect.TERROR, dur = 6, msg = 'erupts from below with a terrifying shriek!' },
    drain = { periodSec = 10, healPct = 0.5 },
    phases = {
        { hp = 40, action = 'fury',   att = 4000, haste = 130, msg = 'enters Acidic Frenzy!' },
        { hp = 25, action = 'dispel', count = 4, msg = 'vomits Null Acid -- enhancements stripped!' },
    },
    doom = { startHpp = 18, dur = 28, msg = 'marks you with Glavoid\'s Doom Slime!' },
}

-- Tinnin [Lv250] - pre-Apex bridge: full suite, forgiving sustain/clock
catalog.mechCfgs[11409] = {
    name   = 'Tinnin',
    enrage = { sec = 240, att = 5000, haste = 200, msg = 'Tinnin\'s fury spirals out of control -- ENRAGE!' },
    -- Tinnin keeps its native Pyric/Polar Bulwark shields instead of the
    -- generic stance dance; stacking both could leave no intended damage
    -- counterplay during a shield window.
    aoe   = { periodSec = 11, dmgPct = 24, msg = 'releases a Crimson Breath nova!' },
    cc    = { periodSec = 19, effect = xi.effect.TERROR, dur = 7, msg = 'unleashes a Dragon\'s Roar of pure dominion!' },
    drain = { periodSec = 10, healPct = 0.75 },
    phases = {
        { hp = 60, action = 'fury',   att = 3500, haste = 120, msg = 'enters Dragon Phase!' },
        { hp = 25, action = 'nuke',   dmgPct = 42, msg = 'channels Tinnin\'s Final Darkness!' },
        { hp = 15, action = 'dispel', count = 5, msg = 'shatters enhancements with Wyrm\'s Negation!' },
        { hp = 10, action = 'enrage', att = 8000, haste = 250, msg = 'transcends mortality!' },
    },
    doom = { startHpp = 12, dur = 25, msg = 'marks you with Wyrm\'s Brand -- run or die!' },
}

-- -------------------------
-- Empy set (Abyssea NMs) groupIds: Aello=11413, Iratham=11411, Briareus=11410, Itzpapalotl=11412, Hadhayosh=11414
-- -------------------------

-- Aello entry - light anti-turtle drain only
catalog.mechCfgs[11413] = {
    name  = 'Aello',
    drain = { periodSec = 10, healPct = 0.25 },
}

-- Iratham [Lv175] - stance dance: shadow phases + terror
catalog.mechCfgs[11411] = {
    name   = 'Iratham',
    stance = { startHpp = 100, periodSec = 18,
        stances = {
            { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0    }, msg = 'veils itself in Abyssal Shadow -- use magic!' },
            { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'radiates Void Light -- magic cannot pierce it! Use steel!' },
        }
    },
    cc = { periodSec = 22, effect = xi.effect.TERROR, dur = 5, msg = 'howls with an Abyssal Wail!' },
}

-- Briareus [Lv200] - mid-tier: AoE + drain + nuke
catalog.mechCfgs[11410] = {
    name  = 'Briareus',
    aoe   = { periodSec = 12, dmgPct = 22, msg = 'swings a Hundred-Arm Cyclone!' },
    drain = { periodSec = 9,  healPct = 0.25 },
    phases = {
        { hp = 40, action = 'nuke',  dmgPct = 38, msg = 'focuses all hundred fists into one Void Strike!' },
        { hp = 20, action = 'fury',  att = 3500, haste = 110, msg = 'enters Hecatoncheires Rage!' },
    },
}

-- Itzpapalotl [Lv225] - hard: stance + CC + drain + fury + dispel + doom
catalog.mechCfgs[11412] = {
    name   = 'Itzpapalotl',
    stance = { startHpp = 100, periodSec = 16,
        stances = {
            { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0    }, msg = 'coats its obsidian wings in Abyssal Steel -- use magic!' },
            { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'unfurls Void Pinions -- magic is useless! Use steel!' },
        }
    },
    cc    = { periodSec = 20, effect = xi.effect.TERROR, dur = 6, msg = 'shrieks with a Celestial Moth Scream!' },
    drain = { periodSec = 10, healPct = 0.5 },
    phases = {
        { hp = 40, action = 'fury',   att = 4000, haste = 130, msg = 'enters Obsidian Butterfly Fury!' },
        { hp = 25, action = 'dispel', count = 4, msg = 'purges enhancements with Void Scatter!' },
    },
    doom = { startHpp = 18, dur = 28, msg = 'brands you with the Clipped Wing Curse!' },
}

-- Hadhayosh [Lv250] - pre-Apex bridge: full suite, forgiving sustain/clock
catalog.mechCfgs[11414] = {
    name   = 'Hadhayosh',
    enrage = { sec = 240, att = 5000, haste = 200, msg = 'Hadhayosh loses all restraint -- ENRAGE!' },
    stance = { startHpp = 100, periodSec = 15,
        stances = {
            { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0    }, msg = 'bristles with Abyssal Hide -- blades cannot bite! Use magic!' },
            { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'absorbs the Void into its mass -- magic is void! Use steel!' },
        }
    },
    aoe   = { periodSec = 11, dmgPct = 25, msg = 'pulses with a Void Shockwave across the earth!' },
    cc    = { periodSec = 18, effect = xi.effect.TERROR, dur = 7, msg = 'bellows a world-shaking Behemoth\'s Roar!' },
    drain = { periodSec = 10, healPct = 0.75 },
    phases = {
        { hp = 65, action = 'fury',   att = 3500, haste = 120, msg = 'enters Abyssal Phase -- attacks accelerate!' },
        { hp = 30, action = 'nuke',   dmgPct = 44, msg = 'converges the Abyss into one Final Erasure!' },
        { hp = 15, action = 'dispel', count = 5, msg = 'unmakes your enhancements with Void Annihilation!' },
        { hp = 10, action = 'enrage', att = 8000, haste = 250, msg = 'becomes the Void itself!' },
    },
    doom = { startHpp = 12, dur = 25, msg = 'marks you with the Mark of Nothingness!' },
}

-- =========================================================
-- LOOT POOL HELPER
--   Returns a flat list of base item IDs for ONE set across all jobs.
--   The Spawner uses this to roll a per-set random drop on each kill:
--     killing a sky god  -> AF base pool
--     killing a Unity NM -> Relic base pool
--     killing Abyssea NM -> Empyrean base pool
-- =========================================================
function catalog.buildLootPool(setKey)
    local pool = {}
    for _, jobPieces in pairs(catalog.pieces) do
        local set = jobPieces[setKey]
        if set then
            for _, slot in pairs(set) do
                if slot[1] and slot[1] > 0 then
                    table.insert(pool, slot[1])
                end
            end
        end
    end
    return pool
end

-- =========================================================
-- JOB-TARGETED LOOT POOL  (catalog.buildJobLootPool)
--   Returns just the killer's-job base pieces for ONE set.
--   With 22 jobs in the catalog this is a 5-item pool instead
--   of the 110-item full pool - used in concert with mainJobBias
--   below to slash the coupon-collector grind from ~250 kills to
--   ~50-80 kills for a full set on a specific job.
-- =========================================================
function catalog.buildJobLootPool(jobId, setKey)
    local pool = {}
    local jobPieces = catalog.pieces[jobId]
    if not jobPieces then
        return pool
    end
    local set = jobPieces[setKey]
    if not set then
        return pool
    end
    for _, slot in pairs(set) do
        if slot[1] and slot[1] > 0 then
            table.insert(pool, slot[1])
        end
    end
    return pool
end

-- =========================================================
-- MAIN-JOB DROP BIAS
--   Probability that an NM drop is rolled from the killer's main-job
--   pool (5 items) instead of the full set-wide pool (~110 items).
--
--     0.0  Pure random across all jobs (legacy behaviour).
--          Expected ~251 kills for a full 5-piece set on one job.
--     0.5  ~50/50 between job-locked and random pool.
--          Expected ~50-80 kills for a full set on one job.
--     1.0  Always drops a piece for the killer's main job.
--          Expected ~11 kills for a full set (coupon collector
--          on the 5 specific slots).
--
--   If the killer's main job has no entries in catalog.pieces
--   (e.g. unsupported job), the roll falls through to the full
--   pool regardless of this value.
-- =========================================================
catalog.mainJobBias = 0.5

-- =========================================================
-- NM LOOT DROP  (Reforge_System.rollLootDrop)
--   dropChance      : probability an NM kill drops a JSE piece at all.
--                     Was a GUARANTEED base piece every kill; lowered
--                     2026-07-09 (player feedback) so Marks are the steady
--                     deterministic path and a drop is a rarer bonus.
--                     1.0 = every kill.
--   Drops are always the BASE (i109) piece -- the start of the upgrade
--   line (owner request 2026-07-11; the short-lived pre-upgraded +1/+2/+3
--   drops skipped the base->+3 mark grind the vendor is built around).
-- =========================================================
catalog.dropChance = 0.30

return catalog
