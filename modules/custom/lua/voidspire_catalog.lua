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
--  * Mob LEVEL is capped at 150. Depth escalates through controlled HP,
--    offense, mechanics, and affixes rather than unhittable level scaling.
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
    x        = 2.0,
    y        = -34.0,
    z        = -463.0,
    rotation = 128,
}

-- Three interchangeable copies of the Warden, spread ~8 units apart on the
-- SOUTH/entry plaza, so several players can start independent runs at once.
catalog.npcPositions =
{
    { x = 2.0,  y = -34.0, z = -463.0, rot = 128 },
    { x = 10.0, y = -34.0, z = -471.0, rot = 128 },
    { x = 18.0, y = -34.0, z = -463.0, rot = 128 },
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
    -- Level reaches 150 just before floor 100 and never exceeds the server cap.
    level = { base = 115, per = 0.36, cap = 150 },

    -- Exact per-mob HP anchors. Voidspire.lua linearly interpolates between
    -- them, eliminating donor-pool HP variance. Floors 90-99 occupy the
    -- Abyssea T2 band; floor 100 is the 14M T3-equivalent Empyrean gate.
    hpAnchors =
    {
        { floor = 1,   hp =   150000 },
        { floor = 20,  hp =   300000 },
        { floor = 40,  hp =   600000 },
        { floor = 60,  hp =  1500000 },
        { floor = 79,  hp =  3500000 },
        { floor = 80,  hp =  4000000 },
        { floor = 89,  hp =  6000000 },
        { floor = 90,  hp =  8000000 },
        { floor = 99,  hp = 10000000 },
        { floor = 100, hp = 14000000 },
        { floor = 120, hp = 20000000 },
    },

    -- One opponent per floor keeps this solo-with-trusts progression readable.
    mobsBase = 1, mobsStep = 1000, mobsCap = 1,

    -- Per-mob mods, set AFTER spawn() (spawn recalculates stats). Two groups:
    --   OFFENSE (mob -> you): ramps HARD so deep floors eventually overwhelm.
    --   ENDURANCE (you -> mob): ramps GENTLY so the mob stays damageable; the
    --   wipe should come from incoming damage, not an unhittable target.
    -- HASTE_GEAR caps at 256 (=25%, engine gear-haste cap).
    mods =
    {
        -- offense (physical)
        [xi.mod.ATT]           = { base = 1500, per = 65,   cap = 8000 },
        [xi.mod.ACC]           = { base = 300,  per = 6,    cap = 900 },
        [xi.mod.STR]           = { base = 50,   per = 3,    cap = 350 },
        [xi.mod.DEX]           = { base = 50,   per = 3,    cap = 350 },
        [xi.mod.HASTE_GEAR]    = { base = 40,   per = 1.3,  cap = 170 },
        [xi.mod.DOUBLE_ATTACK] = { base = 5,    per = 0.2,  cap = 25 },
        [xi.mod.TRIPLE_ATTACK] = { base = 0,    per = 0.1,  cap = 10 },
        -- Weapon DMG used to sit at ~level (Suzaku Dread Dive ~400-600 at F95-100).
        -- MAIN_DMG_RATING feeds GetWeaponDamage so physical specials track the floor.
        [xi.mod.MAIN_DMG_RATING] = { base = 25, per = 2.0,  cap = 220 },
        -- offense (magic) — Stormwind / Firaga / Flare were dead without this.
        -- Magical skills use MATT/MDEF and MAGIC_DAMAGE; ATT alone does nothing.
        -- F100 ballpark: MATT~1400, MAGIC_DAMAGE~850 → Stormwind thousands, not ~50.
        [xi.mod.MATT]          = { base = 200,  per = 12,   cap = 1400 },
        [xi.mod.MACC]          = { base = 200,  per = 6,    cap = 900 },
        [xi.mod.INT]           = { base = 40,   per = 2.5,  cap = 300 },
        [xi.mod.MAGIC_DAMAGE]  = { base = 50,   per = 8,    cap = 900 },
        -- endurance (gentle, low caps -- keep mobs damageable)
        [xi.mod.DEF]           = { base = 0,    per = 5,    cap = 500 },
        [xi.mod.EVA]           = { base = 0,    per = 3,    cap = 300 },
    },
}

-- Mob pool by floor band -- reuses the Game Master pools for escalating
-- silhouettes. Voidspire.lua `require`s game_master_catalog and pulls
-- difficulties[diff].mobs for the band the current floor falls into.
catalog.bands =
{
    { upTo = 39,        diff = 'Easy'   },
    { upTo = 69,        diff = 'Normal' },
    { upTo = 89,        diff = 'Hard'   },
    { upTo = math.huge, diff = 'Insane' },
}

-- ============================ AFFIXES ============================
-- Void-themed modifiers layered onto floor mobs as you descend. DATA-driven
-- (mod deltas + optional hpMult) so Voidspire.lua can ADD them on top of the
-- base floor scaling in a single setMod pass -- no overwrite, no addMod needed.
--   Starts at `affixStartFloor`; +1 active affix every `affixStep` floors,
--   capped at `affixCap`. The active set is rolled per run and shown to you.
catalog.affixStartFloor = 40
catalog.affixStep       = 25
catalog.affixCap        = 3
catalog.affixes =
{
    { id = 'ravenous',   label = 'Ravenous',   desc = 'A faint void-current closes minor wounds.',
      mods = { [xi.mod.REGEN] = 20 } },
    { id = 'cruel',      label = 'Cruel',      desc = 'Their blows fall like falling stars.',
      mods = { [xi.mod.ATT] = 800, [xi.mod.STR] = 50 } },
    { id = 'manic',      label = 'Manic',      desc = 'A frenzy of impossible speed.',
      mods = { [xi.mod.HASTE_GEAR] = 40, [xi.mod.DOUBLE_ATTACK] = 8 } },
    { id = 'unerring',   label = 'Unerring',   desc = 'Nothing escapes their sight -- evasion is useless here.',
      mods = { [xi.mod.ACC] = 150 } },
    { id = 'warded',     label = 'Warded',     desc = 'A void-shell blunts every blow.',
      mods = { [xi.mod.DMGPHYS] = -1000, [xi.mod.DMGMAGIC] = -1000 } },
    { id = 'venomous',   label = 'Venomous',   desc = 'Their touch corrodes flesh and magic alike.',
      mods = { [xi.mod.ATT] = 500, [xi.mod.MATT] = 250 } },
    { id = 'phantasmal', label = 'Phantasmal', desc = 'Half-dreamed, and maddeningly slippery.',
      mods = { [xi.mod.EVA] = 100 } },
    { id = 'colossal',   label = 'Colossal',   desc = 'Bloated with stolen life.',
      hpMult = 1.15 },
}

-- ============================ REWARDS ============================
-- Per-floor-clear marks. MODEST by design -- the Voidspire's prize is the
-- leaderboard, not a mark farm (Hunting League stays the mark economy).
--   marks for clearing floor F = markBase + markPerFloor * F
catalog.markBase     = 5
catalog.markPerFloor = 2

-- Depth milestones: bonus marks awarded the FIRST clear of that floor each
-- UTC week. RELAUNCH: per-week-per-character gate (VS_MS<floor>_Week in
-- Voidspire.lua onFloorCleared) -- closes the per-run mark farm where floor 25
-- paid 10k marks on EVERY descent. Titles are still one-time, granted through
-- the achievement system (achievements.lua -> onVoidspireFloor); owned title no-op.
catalog.milestones =
{
    { floor = 10,  marks = 50  },
    { floor = 25,  marks = 150 },
    { floor = 50,  marks = 350 },
    { floor = 75,  marks = 600 },
    { floor = 100, marks = 1000 },
}

-- ============================ FLOOR MECHANICS ============================
-- Per-band hardcore mechanics (mob_mechanics_library.lua), keyed by the
-- FIRST floor of each band. Voidspire.lua picks the highest key <= floor.
-- Escalating identity: shallow floors feel manageable; deep floors punish.
-- Pool silhouettes change at floors 40, 70, and 90; mechanics become serious
-- at floor 80 and reach their T3-equivalent capstone at floor 100.
catalog.floorMechanics =
{
    -- Floors 1-39: accessible opening climb; no sustain tax.
    [1] = {
        name   = 'Nightmare Vanguard',
        enrage = { sec = 300, att = 2000, haste = 80, msg = 'grows impatient -- its assault quickens!' },
    },

    -- Floors 40-59: introduce light periodic pressure.
    [40] = {
        name   = 'Voidwalker Scout',
        aoe    = { periodSec = 30, dmgPct = 5, msg = 'releases a shallow pulse of void energy!' },
        enrage = { sec = 300, att = 2000, haste = 80, msg = 'presses the assault!' },
    },

    -- Floors 60-79: teach the stance before the real struggle begins.
    [60] = {
        name   = 'Jailer of the Deep',
        stance = { startHpp = 75, periodSec = 30, stances = {
            { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'hardens against weapons -- switch to magic!' },
            { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'wards off magic -- cut it down with steel!' },
        } },
        aoe    = { periodSec = 25, dmgPct = 8, msg = 'erupts in a shockwave of void energy!' },
        enrage = { sec = 300, att = 2500, haste = 100, msg = 'tightens its chains and presses the assault!' },
    },

    -- Floors 80-89: T1-to-T2 bridge. This is where the climb becomes serious.
    [80] = {
        name   = 'Voidwalker Lord',
        stance = { startHpp = 80, periodSec = 25, stances = {
            { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'phases beyond steel -- magic only!' },
            { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'turns magic aside -- weapons only!' },
        } },
        aoe    = { periodSec = 22, dmgPct = 10, msg = 'detonates the void -- shockwave tears outward!' },
        enrage = { sec = 300, att = 3000, haste = 100, msg = 'unbinds its full power!' },
        phases = {
            { hp = 50, action = 'nuke', dmgPct = 15, msg = 'collapses a pocket of void-space!' },
        },
    },

    -- Floors 90-99: Abyssea T2 pressure, with restrained CC and no drain.
    [90] = {
        name   = "World's End Gate",
        stance = { startHpp = 80, periodSec = 20, stances = {
            { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'phases beyond steel -- magic only!' },
            { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'wards off magic -- weapons only!' },
        } },
        aoe    = { periodSec = 20, dmgPct = 12, msg = 'detonates the void around it!' },
        cc     = { periodSec = 35, effect = xi.effect.TERROR, dur = 3, msg = 'fills the air with ancient dread!' },
        enrage = { sec = 360, att = 3500, haste = 120, msg = "the World's End nears -- it goes all out!" },
        phases = {
            { hp = 50, action = 'nuke', dmgPct = 20, msg = 'collapses void-space in a cataclysmic blast!' },
            { hp = 25, action = 'fury', att = 1500, haste = 60, msg = 'erupts in a void frenzy!' },
        },
    },

    -- Floor 100+: T3-equivalent capstone. Hard, but no regen/drain/Doom stack.
    [100] = {
        name   = 'The Nightmare Itself',
        stance = { startHpp = 85, periodSec = 18, stances = {
            { mods = { [xi.mod.DMGPHYS] = -5000, [xi.mod.DMGMAGIC] = 0     }, msg = 'deems your weapons unworthy -- magic only!' },
            { mods = { [xi.mod.DMGPHYS] = 0,     [xi.mod.DMGMAGIC] = -5000 }, msg = 'deems your magic unworthy -- steel only!' },
        } },
        aoe    = { periodSec = 18, dmgPct = 15, msg = 'detonates reality -- a void-shockwave tears through you!' },
        cc     = { periodSec = 30, effect = xi.effect.SILENCE, dur = 5, msg = 'silences the intruders -- magic cut!' },
        enrage = { sec = 480, att = 4000, haste = 140, msg = 'ascends beyond comprehension -- death approaches!' },
        phases = {
            { hp = 50, action = 'nuke', dmgPct = 25, msg = 'collapses the void in a final cataclysm!' },
            { hp = 30, action = 'dispel', count = 3, msg = 'strips away your blessings!' },
            { hp = 15, action = 'fury', att = 2500, haste = 100, msg = 'the nightmare rages against its end!' },
        },
    },
}

-- Per-mobskill incoming-damage caps. Voidspire MATT/MAGIC_DAMAGE scaling
-- makes some family moves (Hakutaku Death Ray) one-shot at deep floors.
-- Applied on spawn via local var; the skill script clamps before takeDamage.
catalog.skillDamageCaps =
{
    Hakutaku = { DeathRay = 5000 },
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
