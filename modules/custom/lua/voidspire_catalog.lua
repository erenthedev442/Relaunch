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

-- One-time-per-character depth milestones: bonus marks + a server announce.
-- Titles are granted through the achievement system (achievements.lua ->
-- onVoidspireFloor) so we reuse existing title plumbing, not invent IDs here.
catalog.milestones =
{
    { floor = 10,  marks = 2500  },
    { floor = 25,  marks = 10000 },
    { floor = 50,  marks = 25000 },
    { floor = 75,  marks = 40000 },
    { floor = 100, marks = 70000 },
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
