-----------------------------------
-- hunters_guild_catalog.lua
--
-- Config for the Hunter's Guild reputation system. Provides earned
-- mark amplifiers across four parallel guilds:
--
--   AF Hunters'     - Wyrm Circuit         (AF Marks amplifier)
--   Relic Hunters'  - TOAU / Desert Beasts (Relic Marks amplifier)
--   Empy Hunters'   - Sky Court            (Empy Marks amplifier)
--   League Hunters' - Apex World Bosses    (HL Points amplifier)
--
-- Each guild has 6 ranks. Reaching a higher rank passively boosts
-- the marks earned in THAT guild's currency at the Reforge / HL
-- spawners. Reaching Grandmaster in multiple guilds unlocks meta-
-- bonuses (Trinity / Apex).
--
-- REP SOURCE - REDESIGN (2026-05-29):
--   v1: rep came passively from Reforge / HL spawner kills. Whatever
--       you grinded, you also leveled the matching guild for free.
--       The rep ladder was just a participation trophy on the grind.
--   v2 (current): rep comes ONLY from killing vanilla HNMs scattered
--       across Vana'diel. The four guilds each have 5 dedicated
--       hunt targets (see catalog.huntTargets below). Reforge / HL
--       kills no longer touch rep - they only AWARD the amplified
--       marks. The amplifier is still applied at the spawner; the
--       guild ladder is climbed by actually traveling to the world
--       and hunting the listed NMs.
--
-- All numbers in one file so balance tuning doesn't require touching
-- the spawner code.
-----------------------------------
local catalog = {}

-- =========================================================
-- RANK LADDER (shared across all four guilds)
-- =========================================================
-- Six ranks, six thresholds, six amplifier values. The amplifier
-- is added to (1.0 + ...) at award time; e.g. Veteran = +25% means
-- final = base * (1 + 0.25).
--
-- Threshold tuning:
--   Apprentice    1 kill (always - entry rank, grants on first kill)
--   Journeyman    ~3 apex kills        (500 rep)
--   Veteran       ~35 apex kills       (5,000 rep)
--   Master        ~170 apex kills      (25,000 rep)
--   Champion      ~370 apex kills      (55,000 rep)
--   Grandmaster   ~670 apex kills      (100,000 rep)
--
-- Apex Reforge NMs give 150 marks/kill; HL apex (Tier V) gives 65.
-- Grandmaster on a Reforge guild is ~670 apex kills, on HL it's
-- ~1,540 Tier V kills - HL is naturally slower to max because its
-- mark values are smaller. Adjust the HL marks side rather than
-- diverging the rep curve.
catalog.ranks =
{
    { idx = 1, label = 'Apprentice',   minRep = 0,       amplifier = 0.00 },
    { idx = 2, label = 'Journeyman',   minRep = 500,     amplifier = 0.10 },
    { idx = 3, label = 'Veteran',      minRep = 5000,    amplifier = 0.25 },
    { idx = 4, label = 'Master',       minRep = 25000,   amplifier = 0.50 },
    { idx = 5, label = 'Champion',     minRep = 55000,   amplifier = 0.75 },
    { idx = 6, label = 'Grandmaster',  minRep = 100000,  amplifier = 1.00 },
}

-- =========================================================
-- THE FOUR GUILDS
-- =========================================================
-- key           - internal identifier; used in CharVar names + lookups
-- label         - human-readable name
-- markType      - short name of the mark currency this guild gates
-- repCv         - CharVar that stores cumulative rep for this guild
-- lifetimeCv    - CharVar to pull from when backfilling existing players
-- isReforge     - true for AF/Relic/Empy (counted toward Trinity Hunter)
--
-- Spawn-side integration:
--   AF / Relic / Empy: Reforge_System.lua awardCurrency() bumps repCv
--     by md.marks (the NM's base mark value).
--   HL:                HuntingLeague.lua onMobDeath bumps repCv by
--                      md.points (HL uses 'points' not 'marks').
catalog.guilds =
{
    af = {
        key        = 'af',
        label      = "AF Hunters' Guild",
        markType   = 'AF Marks',
        repCv      = 'Guild_AF_Rep',
        lifetimeCv = 'RF_AF_Marks_Lifetime',
        isReforge  = true,
    },
    relic = {
        key        = 'relic',
        label      = "Relic Hunters' Guild",
        markType   = 'Relic Marks',
        repCv      = 'Guild_Relic_Rep',
        lifetimeCv = 'RF_Relic_Marks_Lifetime',
        isReforge  = true,
    },
    empy = {
        key        = 'empy',
        label      = "Empyrean Hunters' Guild",
        markType   = 'Empy Marks',
        repCv      = 'Guild_Empy_Rep',
        lifetimeCv = 'RF_Empy_Marks_Lifetime',
        isReforge  = true,
    },
    hl = {
        key        = 'hl',
        label      = "League Hunters' Guild",
        markType   = 'Hunt Marks',
        repCv      = 'Guild_HL_Rep',
        lifetimeCv = 'HL_Points_Lifetime',
        isReforge  = false,  -- not part of Trinity, only Apex
    },
}

-- Stable iteration order for menus / leaderboards / docs.
-- AF -> Relic -> Empy -> HL matches the player's typical progression
-- arc on Legendary.
catalog.guildOrder = { 'af', 'relic', 'empy', 'hl' }

-- =========================================================
-- CAPSTONES
-- =========================================================
-- Two cross-guild achievements that unlock when ALL relevant guilds
-- hit Grandmaster simultaneously. Stored as one-time flag CharVars
-- so the achievement chat announcement fires exactly once.
--
-- The bonus stacks ON TOP of the individual guild's Grandmaster +100%.
-- Apex supersedes Trinity (so a player at Apex doesn't double-dip).
catalog.capstones =
{
    trinity = {
        label       = 'Trinity Hunter',
        achievedCv  = 'Title_Trinity_Hunter',
        requires    = { 'af', 'relic', 'empy' },     -- 3 Reforge guilds
        bonus       = 0.25,                           -- +25%
        appliesTo   = { 'af', 'relic', 'empy' },     -- only Reforge marks
    },
    apex = {
        label       = 'Apex Hunter',
        achievedCv  = 'Title_Apex_Hunter',
        requires    = { 'af', 'relic', 'empy', 'hl' }, -- all 4
        bonus       = 0.50,                            -- +50%, supersedes Trinity
        appliesTo   = { 'af', 'relic', 'empy', 'hl' }, -- all marks
    },
}

-- =========================================================
-- BACKFILL POLICY
-- =========================================================
-- Set true to grant existing players retroactive rep equal to their
-- lifetime mark totals on first interaction with the guild system.
-- A per-player Guild_Backfilled = 1 flag prevents re-running.
-- Set to false to ignore lifetime CharVars (cold-start for everyone).
--
-- NOTE on v2 redesign: backfill stays available but is mostly
-- legacy now - under the Vana'diel-hunt model rep ONLY comes from
-- vanilla NM kills, so backfilling from old lifetime mark totals
-- would let veterans skip the new hunt requirement. Keep this
-- false in production unless you want to grandfather in old
-- progress on a specific server cohort.
catalog.backfillFromLifetime = false
catalog.backfillFlagCv       = 'Guild_Backfilled'

-- =========================================================
-- VANA'DIEL HUNT TARGETS (v2 rep source)
-- =========================================================
-- Each guild owns 5 vanilla HNMs from open-world FFXI zones. The
-- player travels to the zone, kills the NM, and gets `baseRep`
-- credited to the matching guild. Tier values (1..5) inform the
-- per-kill rep:
--   tier 1 (easiest camp) -> 500 rep
--   tier 2                -> 750 rep
--   tier 3                -> 1000 rep
--   tier 4                -> 1500 rep
--   tier 5 (apex HNM)     -> 2500 rep
-- A player mixing kills across tiers reaches Grandmaster (100k
-- rep) in roughly 80-100 mixed-difficulty kills per guild.
--
-- NM script files verified on disk at:
--   scripts/zones/<zone>/mobs/<name>.lua
-- mob_groups respawn timer overrides applied via
--   modules/custom/sql/hunters_guild_hunt_respawns.sql
-- so these NMs are camp-viable on a low-pop server (20min .. 60min
-- respawn instead of the vanilla 21h..168h windows).
--
-- Selection criteria:
--   * Lv90+ class HNM (player request: endgame-only)
--   * In a non-instanced, walkable vanilla zone (no Dynamis /
--     Nyzul / Limbus / Salvage where the player can't just
--     show up)
--   * NOT already used by Reforge (Genbu/Suzaku/Seiryu/Byakko/
--     Kirin, Bukhis/Khun/Padfoot/Glavoid/Tinnin, Aello/Iratham/
--     Briareus/Itzpapalotl/Hadhayosh) or HL (Lizzy/Valkurm/Tom
--     Tit Tat/Roc/Bomb Queen/Aquarius/Serket/Vrtra/Simurgh/
--     Nidhogg/King Behemoth/Kirin/AV/PW/Shinryu)
--   * Each guild has its own thematic identity so the player
--     thinks "I'm hunting wyrms today" not "5 random NMs"
catalog.huntTargets =
{
    -- AF Hunters' - Wyrm Circuit (fire / forest / sea / sky / apex dragons)
    af =
    {
        { tier = 1, baseRep =  500, name = 'Tarasque',           label = 'Tarasque',
          zone = 'Ifrits_Cauldron',         zoneId = 205, groupId = 29 },
        { tier = 2, baseRep =  750, name = 'Capricornus',        label = 'Capricornus',
          zone = 'Jugner_Forest',           zoneId = 104, groupId = 76 },
        { tier = 3, baseRep = 1000, name = 'Charybdis',          label = 'Charybdis',
          zone = 'Sea_Serpent_Grotto',      zoneId = 176, groupId = 51 },
        { tier = 4, baseRep = 1500, name = 'Tiamat',             label = 'Tiamat',
          zone = 'Attohwa_Chasm',           zoneId =   7, groupId = 46 },
        { tier = 5, baseRep = 2500, name = 'Fafnir',             label = 'Fafnir',
          zone = 'Dragons_Aery',            zoneId = 154, groupId =  5 },
    },

    -- Relic Hunters' - TOAU / Desert Beasts (cave & desert NMs)
    relic =
    {
        { tier = 1, baseRep =  500, name = 'Cactrot_Rapido',     label = 'Cactrot Rapido',
          zone = 'Eastern_Altepa_Desert',   zoneId = 114, groupId = 52 },
        { tier = 2, baseRep =  750, name = 'Lord_of_Onzozo',     label = 'Lord of Onzozo',
          zone = 'Labyrinth_of_Onzozo',     zoneId = 213, groupId = 16 },
        { tier = 3, baseRep = 1000, name = 'King_Vinegarroon',   label = 'King Vinegarroon',
          zone = 'Western_Altepa_Desert',   zoneId = 125, groupId = 26 },
        { tier = 4, baseRep = 1500, name = 'Khimaira',           label = 'Khimaira',
          zone = 'Caedarva_Mire',           zoneId =  79, groupId = 59 },
        { tier = 5, baseRep = 2500, name = 'Cerberus',           label = 'Cerberus',
          zone = 'Mount_Zhayolm',           zoneId =  61, groupId = 37 },
    },

    -- Empy Hunters' - Sky Court (Tu'Lia + Riverne sky-zone NMs)
    empy =
    {
        { tier = 1, baseRep =  500, name = 'Faust',              label = 'Faust',
          zone = 'The_Shrine_of_RuAvitau',  zoneId = 178, groupId =  6 },
        { tier = 2, baseRep =  750, name = 'Despot',             label = 'Despot',
          zone = 'RuAun_Gardens',           zoneId = 130, groupId = 13 },
        { tier = 3, baseRep = 1000, name = 'Steam_Cleaner',      label = 'Steam Cleaner',
          zone = 'VeLugannon_Palace',       zoneId = 177, groupId = 15 },
        { tier = 4, baseRep = 1500, name = 'Brigandish_Blade',   label = 'Brigandish Blade',
          zone = 'VeLugannon_Palace',       zoneId = 177, groupId = 14 },
        { tier = 5, baseRep = 2500, name = 'Bahamut',            label = 'Bahamut',
          zone = 'Riverne-Site_B01',        zoneId =  29, groupId = 17 },
    },

    -- League Hunters' - Apex World Bosses (open-world tyrants)
    hl =
    {
        { tier = 1, baseRep =  500, name = 'Bune',               label = 'Bune',
          zone = 'Gustav_Tunnel',           zoneId = 212, groupId =  6 },
        { tier = 2, baseRep =  750, name = 'Carmine_Dobsonfly',  label = 'Carmine Dobsonfly',
          zone = 'Riverne-Site_A01',        zoneId =  30, groupId = 12 },
        -- Aspidochelone (Valley_of_Sorrows) and Behemoth (Behemoths_Dominion)
        -- were REMOVED from huntTargets 2026-07-13. hunters_guild_hunts.lua
        -- installs one addOverride per target on `xi.zones.<Z>.mobs.<M>.onMobDeath`,
        -- but those xi.zones tables are only populated when a mob first spawns
        -- (C++ CacheLuaObjectFromFile is lazy) -- these two never got pre-cached
        -- pre-boot, so applyOverride's walk failed and the hunt-rep hook silently
        -- no-op'd. Log confirmed 8+ days of "Override not applied" at every deploy.
        -- To re-enable hunt-rep for these: hook via xi.mob.onMobDeathEx (real
        -- engine hook, fires per alliance member) or attach a DEATH listener from
        -- their Zone.onInitialize -- both are supported patterns.
        { tier = 5, baseRep = 2500, name = 'Jormungand',         label = 'Jormungand',
          zone = 'Uleguerand_Range',        zoneId =   5, groupId = 40 },
    },
}

-- =========================================================
-- PER-NM REP COOLDOWN
-- =========================================================
-- Seconds before the SAME NM can award guild rep to the same player
-- again (charvar HGRepCD_<name>, enforced in hunters_guild_hunts.lua).
--
-- Policy 2026-07-14 (owner): 24 HOURS per NM per player. Faster kill
-- rotation was letting a determined camper burn through guild rep by
-- clearing the same 30-min respawn NM repeatedly; a 24h floor makes each
-- unique hunt NM a once-a-day rep source and forces breadth (18 NMs)
-- over depth (1 NM ground 48 times) to progress the guilds.
--
-- Also still solves the original problem this cooldown was built for
-- (Ropraz report 2026-07-09): King Vinegarroon and Fafnir have
-- Affinity-NM copies in the same zone that share the retail mob script,
-- and without a cooldown the 30s affinity repop would be farmable for
-- full rep every kill.
--
-- Side effect the earlier comment warned about ("raising above respawn
-- silently blocks rep on every other kill") is now the DESIRED behavior:
-- only one credited kill per NM per day, regardless of how many times
-- the mob repops in the meantime.
catalog.repCooldownSeconds = 86400

-- =========================================================
-- ALLIANCE / PARTY CREDIT POLICY
-- =========================================================
-- killerOnly = false means ALL members of the killer's alliance/party
-- receive rep when the NM dies. This encourages group hunts and means
-- every participant earns guild progression regardless of who landed
-- the killing blow. (No half-credit option in v2 - keep the model simple.)
catalog.killerOnly = false

return catalog
