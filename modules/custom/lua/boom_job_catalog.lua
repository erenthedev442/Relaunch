-----------------------------------
-- boom_job_catalog.lua
--
-- Config for the custom job "Boom" (relaunch), which repurposes the Summoner
-- slot (job id 15) into a pet-less staff melee/hybrid DD. See BOOM_JOB.md.
--
-- Everything here is a plain modifier or a spell id, so BoomJob.lua applies it
-- with addMod + onGameIn re-apply (no rebuild). TUNE IT ALL HERE.
-----------------------------------
local catalog = {}

-- The job slot Boom lives on. SMN is repurposed; the client still says "Summoner".
catalog.JOB = xi.job.SMN  -- 15

-- ── Job traits ──────────────────────────────────────────────────────────────
-- Flat additive mods applied while SMN(=Boom) is the player's MAIN job. Skill
-- mods (STAFF/ELEM) grant combat + magic skill directly, so we never touch
-- skill_caps or grades.cpp. Values are PLACEHOLDER — tune in playtest.
catalog.traits =
{
    { xi.mod.HP,            800 },  -- SMN base HP is very low; real melee survivability
    { xi.mod.STR,            40 },
    { xi.mod.DEX,            20 },
    { xi.mod.VIT,            20 },
    { xi.mod.ATTP,           25 },  -- +25% melee attack
    { xi.mod.ACC,            50 },
    { xi.mod.DOUBLE_ATTACK,  12 },  -- +12%
    { xi.mod.CRITHITRATE,     8 },  -- +8% crit
    { xi.mod.STORETP,        40 },
    { xi.mod.STAFF,         250 },  -- staff combat skill (WS access + damage)
    { xi.mod.ELEM,          250 },  -- elemental magic skill (nuke acc/damage + detonation scaling)
    { xi.mod.MATT,           40 },
    { xi.mod.MACC,           40 },
    { xi.mod.FASTCAST,       25 },  -- hybrid: weave nukes between swings
}

-- ── The "Boom" spells (cast them -- detonation is per-spell) ─────────────────
-- Granted on login (addSpell) + made castable by the SMN slot via
-- boom_job_spells.sql (jobs-blob byte 15). On cast, each rolls `chance`% to
-- DETONATE for `mult` x the base blast (see catalog.boom). Bigger spells boom
-- bigger -- everything is a real cast, no commands.
catalog.spells =
{
    -- Tier-III nukes: the core handful, small detonation.
    { id = 146, name = 'Stone III',    chance = 15, mult = 1 },
    { id = 151, name = 'Water III',    chance = 15, mult = 1 },
    { id = 156, name = 'Aero III',     chance = 15, mult = 1 },
    { id = 161, name = 'Fire III',     chance = 15, mult = 1 },
    { id = 166, name = 'Blizzard III', chance = 15, mult = 1 },
    { id = 171, name = 'Thunder III',  chance = 15, mult = 1 },
    -- Ancient Magic: the BIG boom -- higher chance, far bigger blast + AoE.
    { id = 204, name = 'Flare',   chance = 35, mult = 5, aoe = 10 },
    { id = 206, name = 'Freeze',  chance = 35, mult = 5, aoe = 10 },
    { id = 208, name = 'Tornado', chance = 35, mult = 5, aoe = 10 },
    { id = 210, name = 'Quake',   chance = 35, mult = 5, aoe = 10 },
    { id = 212, name = 'Burst',   chance = 35, mult = 5, aoe = 10 },
    { id = 214, name = 'Flood',   chance = 35, mult = 5, aoe = 10 },
}

-- Enspells -- casting ANY of these is "Ignite": it opens a window where every
-- nuke's detonation chance is boosted, and the enspell's own melee enchant
-- supports the hybrid. Cast, don't command.
catalog.enspells = { 100, 101, 102, 103, 104, 105 }  -- Enfire/Enblizzard/Enaero/Enstone/Enthunder/Enwater
catalog.ignite =
{
    duration    = 60,    -- seconds the boosted-detonation window lasts
    boostChance = 45,    -- detonation % floor while Ignite is up
    untilVar    = 'Boom_IgniteUntil',
    msg         = 'IGNITE!! Your staff blazes -- spells now detonate readily!',
}

-- ── Detonation damage ───────────────────────────────────────────────────────
-- dmg = (INT*intMult + M.Atk*mattMult + base) * spell.mult, capped. A spell's
-- `aoe` radius > 0 (else aoeRadius) splashes the blast to nearby foes.
catalog.boom =
{
    intMult   = 20,
    mattMult  = 12,
    base      = 3000,
    cap       = 99999,    -- engine damage display ceiling
    aoeRadius = 0,        -- default single target (a spell's own `aoe` overrides)
    msg       = 'BOOM!! Your spell detonates!',
}

return catalog
