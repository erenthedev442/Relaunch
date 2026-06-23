-----------------------------------
-- voidspire_catalog.lua
-- Config for The Voidspire (modules/custom/lua/Voidspire.lua): an ENDLESS,
-- escalating wave gauntlet. Descend floor by floor; each floor is harder than
-- the last; a wipe ends the run and records your deepest floor.
--
--   Score  = best floor ever reached (CharVar Voidspire_Best_Floor),
--            shown in-game + ranked on the leaderboard website.
--
-- Design notes:
--  * Built on the Game Master wave engine (GameMaster.lua): same ring-spawn,
--    claim/enmity lock, NO_CAPACITY_POINTS, and dangling-ref-safe teardown.
--    Reuses the GM mob pool (groupIds 11400-11425 in
--    modules/custom/sql/hunting_league_gm_home_mobs.sql) so this needs NO SQL.
--  * Mob LEVEL is capped (~205). The Insane gods have fixed HP overrides and
--    accuracy/evasion outrun L99 gear past ~L200 (see GameMaster Insane notes),
--    so depth escalates through MODS + HP + mob COUNT + AFFIXES, not raw level.
--  * Difficulty should kill you via INCOMING damage (offense/haste), not by
--    making mobs unkillable -- so offense ramps hard while EVA/DEF creep gently.
--  * Lore: a spire bored down into the sealed Nightmare Court. Deeper floors =
--    deeper Courts (Voidwalkers -> Jailers -> Voidwalker Lords -> World's End).
--
-- ALL NUMBERS HERE ARE TUNING KNOBS. Expect to adjust them after playtesting.
-----------------------------------
local catalog = {}

-- Where the Warden NPC + the run live. Escha_RuAun (289): the same open,
-- trust-enabled wave arena the Game Master uses. Warden sits opposite the GM
-- (GM is at x=3.0) on the entry plaza -- nudge with !pos in-game if it overlaps.
catalog.npcPos =
{
    zone     = 'Escha_RuAun',
    zoneId   = 289,
    x        = -3.000,
    y        = -34.277,
    z        = -466.980,
    rotation = 192,
}

-- Run tempo (seconds). Endless tempo is tighter than the GM's finite waves.
catalog.graceDelay   = 8    -- after "Descend" before floor 1 spawns
catalog.floorDelay   = 6    -- between a cleared floor and the next
catalog.spawnStagger = 1    -- between mobs within a multi-mob floor
catalog.spawnRing    = { minRadius = 6, maxRadius = 12 }

-- ============================ FLOOR SCALING ============================
-- Per-stat scaling with floor F. Voidspire.lua reads these.
-- Standard ramp for a stat = clamp(base + per * (F - 1), .., cap).
catalog.scaling =
{
    -- Mob level: ramps to a HITTABLE cap (~205). Past that, eva/acc outrun L99
    -- gear; difficulty beyond the cap comes from mods/hp/affixes instead.
    level   = { base = 120, per = 2.5, cap = 205 },

    -- HP multiplier on the pool mob's base HP. Endurance grows with depth.
    -- Capped so deep gods stay killable-with-effort, not infinite sponges.
    hpBoost = { base = 4.0, per = 0.30, cap = 30.0 },

    -- Mobs per floor: +1 every `mobsStep` floors, capped (lag + readability).
    mobsBase = 1, mobsStep = 10, mobsCap = 5,

    -- Per-mob mods, set AFTER spawn() (spawn recalculates stats). Two groups:
    --   OFFENSE (mob -> you): ramps HARD so deep floors eventually overwhelm.
    --   ENDURANCE (you -> mob): ramps GENTLY so the mob stays damageable; the
    --   wipe should come from incoming damage, not an unhittable target.
    -- HASTE_GEAR caps at 256 (=25%, engine gear-haste cap).
    mods =
    {
        -- offense
        [xi.mod.ATT]           = { base = 2000, per = 300,  cap = 18000 },
        [xi.mod.ACC]           = { base = 700,  per = 45,   cap = 3200 },
        [xi.mod.STR]           = { base = 100,  per = 12,   cap = 900 },
        [xi.mod.DEX]           = { base = 100,  per = 12,   cap = 900 },
        [xi.mod.HASTE_GEAR]    = { base = 80,   per = 6,    cap = 256 },
        [xi.mod.DOUBLE_ATTACK] = { base = 8,    per = 0.7,  cap = 40 },
        [xi.mod.TRIPLE_ATTACK] = { base = 2,    per = 0.4,  cap = 20 },
        -- endurance (gentle, low caps -- keep mobs damageable)
        [xi.mod.DEF]           = { base = 0,    per = 8,    cap = 600 },
        [xi.mod.EVA]           = { base = 0,    per = 5,    cap = 300 },
    },
}

-- Mob pool by floor band -- reuses the Game Master pools for escalating
-- silhouettes. Voidspire.lua `require`s game_master_catalog and pulls
-- difficulties[diff].mobs for the band the current floor falls into.
catalog.bands =
{
    { upTo = 9,         diff = 'Easy'   },  -- floors 1-9:   classic camp NMs
    { upTo = 24,        diff = 'Normal' },  -- floors 10-24: mid-tier classics
    { upTo = 44,        diff = 'Hard'   },  -- floors 25-44: HNM apex beasts
    { upTo = math.huge, diff = 'Insane' },  -- floors 45+:   gods + wyrms
}

-- ============================ AFFIXES ============================
-- Void-themed modifiers layered onto floor mobs as you descend. DATA-driven
-- (mod deltas + optional hpMult) so Voidspire.lua can ADD them on top of the
-- base floor scaling in a single setMod pass -- no overwrite, no addMod needed.
--   Starts at `affixStartFloor`; +1 active affix every `affixStep` floors,
--   capped at `affixCap`. The active set is rolled per run and shown to you.
catalog.affixStartFloor = 10
catalog.affixStep       = 15
catalog.affixCap        = 5
catalog.affixes =
{
    { id = 'ravenous',   label = 'Ravenous',   desc = 'They regenerate from the Void itself -- sustain your damage.',
      mods = { [xi.mod.REGEN] = 150 } },
    { id = 'cruel',      label = 'Cruel',      desc = 'Their blows fall like falling stars.',
      mods = { [xi.mod.ATT] = 3000, [xi.mod.STR] = 120 } },
    { id = 'manic',      label = 'Manic',      desc = 'A frenzy of impossible speed.',
      mods = { [xi.mod.HASTE_GEAR] = 120, [xi.mod.DOUBLE_ATTACK] = 15 } },
    { id = 'unerring',   label = 'Unerring',   desc = 'Nothing escapes their sight -- evasion is useless here.',
      mods = { [xi.mod.ACC] = 700 } },
    { id = 'warded',     label = 'Warded',     desc = 'A void-shell blunts every blow.',
      mods = { [xi.mod.DMGPHYS] = -10, [xi.mod.DMGMAGIC] = -10 } },
    { id = 'venomous',   label = 'Venomous',   desc = 'Their touch corrodes flesh and magic alike.',
      mods = { [xi.mod.ATT] = 1500, [xi.mod.MATT] = 80 } },
    { id = 'phantasmal', label = 'Phantasmal', desc = 'Half-dreamed, and maddeningly slippery.',
      mods = { [xi.mod.EVA] = 200 } },
    { id = 'colossal',   label = 'Colossal',   desc = 'Bloated with stolen life.',
      hpMult = 1.4 },
}

-- ============================ REWARDS ============================
-- Per-floor-clear marks. MODEST by design -- the Voidspire's prize is the
-- leaderboard, not a mark farm (Hunting League stays the mark economy).
--   marks for clearing floor F = markBase + markPerFloor * F
catalog.markBase     = 5
catalog.markPerFloor = 2

-- Depth milestones: bonus marks awarded EACH time you clear that floor.
-- RE-AWARDABLE PER RUN (2026-06-22, by request) -- the per-character flag check
-- was dropped in Voidspire.lua onFloorCleared, so a deep run pays these bonuses
-- on EVERY descent (a heavy repeatable mark farm), not once per character.
-- Titles are still one-time, granted through the achievement system
-- (achievements.lua -> onVoidspireFloor); granting an owned title is a no-op.
catalog.milestones =
{
    { floor = 10,  marks = 2500  },
    { floor = 25,  marks = 10000 },
    { floor = 50,  marks = 25000 },
    { floor = 75,  marks = 40000 },
    { floor = 100, marks = 70000 },
}

-- ============================ FLOOR MECHANICS ============================
-- Per-band hardcore mechanics (mob_mechanics_library.lua), keyed by the
-- FIRST floor of each band. Voidspire.lua picks the highest key <= floor.
-- Escalating identity: shallow floors feel manageable; deep floors punish.
--   Zone 289 (Escha_RuAun) groupIds for adds:
--     Easy   pool: 11400 (Argus)   -- floors 1-9
--     Normal pool: 11404 (Boggelmann) -- floors 10-24
--     Hard   pool: 11408 (Cerberus)   -- floors 25-44
--     Insane pool: 11412 (Bahamut)    -- floors 45+
-- addLevel kept lower than the floor-mob level so adds die first but still hurt.
catalog.floorMechanics =
{
    -- Floors 1-9: shallow threat. Occasional self-heal + soft enrage if you
    -- turtle. Easy entry -- there's barely a mechanic; just regen pressure.
    [1] = {
        name   = 'Nightmare Vanguard',
        drain  = { periodSec = 12, healPct = 2 },
        enrage = { sec = 300, att = 2000, haste = 80, msg = 'grows impatient -- its assault quickens!' },
    },

    -- Floors 10-24: adds + slow enrage. A feeding swarm: kill the adds or the
    -- boss heals off them. First real mechanical identity.
    [10] = {
        name   = 'Voidwalker Scout',
        drain  = { periodSec = 10, healPct = 2 },
        enrage = { sec = 240, att = 3500, haste = 100, msg = 'feasts on spilled blood -- striking harder!' },
        phases = {
        },
    },

    -- Floors 25-44: stance dance begins. Must switch damage type every cycle.
    -- AoE shockwave added; tighter enrage.
    [25] = {
        name   = 'Jailer of the Deep',
        stance = { startHpp = 90, periodSec = 16, stances = {
            { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'hardens against weapons -- switch to magic!' },
            { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'wards off magic -- cut it down with steel!' },
        } },
        aoe    = { periodSec = 14, dmgPct = 20, msg = 'erupts in a shockwave of void energy!' },
        enrage = { sec = 220, att = 4500, haste = 130, msg = 'tightens its chains -- it presses the assault!' },
    },

    -- Floors 45-74: adds + stance + dispel. Full mid-game pressure.
    -- Adds use Insane-pool groupId (Bahamut) at reduced level.
    [45] = {
        name   = 'Voidwalker Lord',
        stance = { startHpp = 90, periodSec = 14, stances = {
            { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'phases beyond steel -- magic only!' },
            { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'turns magic aside -- weapons only!' },
        } },
        aoe    = { periodSec = 12, dmgPct = 22, msg = 'detonates the void -- shockwave tears outward!' },
        enrage = { sec = 200, att = 6000, haste = 150, msg = 'unbinds its full power -- survive or be swept away!' },
        phases = {
            { hp = 35, action = 'dispel', count = 4, msg = 'rips your blessings away!' },
        },
    },

    -- Floors 75-99: doom + nuke + tight enrage + CC. High pressure all game.
    -- Kill it before enrage or it becomes a wall.
    [75] = {
        name   = "World's End Gate",
        stance = { startHpp = 80, periodSec = 13, stances = {
            { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'phases beyond steel -- magic only!' },
            { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'wards off magic -- weapons only!' },
        } },
        aoe    = { periodSec = 11, dmgPct = 25, msg = 'detonates the void around it!' },
        cc     = { periodSec = 25, effect = xi.effect.TERROR, dur = 5, msg = 'fills the air with ancient dread -- you freeze!' },
        enrage = { sec = 180, att = 7500, haste = 180, msg = "the World's End nears -- it goes all out!" },
        phases = {
            { hp = 50, action = 'nuke', dmgPct = 38, msg = 'collapses void-space in a cataclysmic blast!' },
            { hp = 25, action = 'fury', att = 3500, haste = 120, msg = 'erupts in a void frenzy!' },
        },
        doom   = { startHpp = 12, dur = 28, msg = 'marks you for oblivion -- escape or perish!' },
    },

    -- Floors 100+: THE NIGHTMARE. Full kit, mean timers, tight doom.
    -- Silence CC, heavy adds (int16-safe regen 25000), 165s enrage. No quarter.
    [100] = {
        name   = 'The Nightmare Itself',
        stance = { startHpp = 90, periodSec = 12, stances = {
            { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'deems your weapons unworthy -- magic only!' },
            { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'deems your magic unworthy -- steel only!' },
        } },
        aoe    = { periodSec = 10, dmgPct = 28, msg = 'detonates reality -- a void-shockwave tears through you!' },
        cc     = { periodSec = 20, effect = xi.effect.SILENCE, dur = 8, msg = 'silences the intruders -- magic cut!' },
        drain  = { periodSec = 9, healPct = 2 },
        enrage = { sec = 165, att = 9000, haste = 220, msg = 'ascends beyond comprehension -- death approaches!' },
        phases = {
            { hp = 50, action = 'nuke', dmgPct = 42, msg = 'collapses the void in a final cataclysm!' },
            { hp = 30, action = 'dispel', count = 5, msg = 'strips every blessing -- you stand naked before the nightmare!' },
            { hp = 15, action = 'fury', att = 5000, haste = 150, msg = 'the nightmare rages against its end!' },
        },
        doom   = { startHpp = 10, dur = 25, msg = 'seals your doom -- the nightmare claims you!' },
    },
}

-- Flavor banners announced the first time you cross into a new Court depth
-- during a run (cosmetic only).
catalog.depthBanners =
{
    { floor = 1,   text = 'The Voidspire opens. The Nightmare Court stirs below.' },
    { floor = 10,  text = 'You descend among the Voidwalkers.' },
    { floor = 25,  text = 'The Jailers take notice of your trespass.' },
    { floor = 50,  text = 'The Voidwalker Lords rise to meet you.' },
    { floor = 75,  text = "You stand at the threshold of the World's End." },
    { floor = 100, text = 'Beyond here, only the Nightmare remains. How deep dare you go?' },
}

return catalog
