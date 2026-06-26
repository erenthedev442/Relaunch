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
    { xi.mod.HP,            500 },  -- SMN base HP is low; bring it up
    { xi.mod.STR,            30 },
    { xi.mod.VIT,            15 },
    { xi.mod.ATTP,           20 },  -- +20% melee attack
    { xi.mod.ACC,            40 },
    { xi.mod.DOUBLE_ATTACK,  10 },  -- +10%
    { xi.mod.STORETP,        30 },
    { xi.mod.STAFF,         200 },  -- staff combat skill (WS access + damage)
    { xi.mod.ELEM,          200 },  -- elemental magic skill (nuke acc + damage)
    { xi.mod.MATT,           30 },
    { xi.mod.MACC,           30 },
    { xi.mod.FASTCAST,       20 },  -- hybrid: cast between swings
}

-- ── The "Boom" spells ───────────────────────────────────────────────────────
-- A handful of tier-III elemental nukes. Granted on login (addSpell) and made
-- castable by the SMN slot via boom_job_spells.sql (jobs-blob byte 15). Each has
-- catalog.boom.chance to DETONATE for big bonus damage when cast.
catalog.spells =
{
    { id = 146, name = 'Stone III'    },  -- earth
    { id = 151, name = 'Water III'    },  -- water
    { id = 156, name = 'Aero III'     },  -- wind
    { id = 161, name = 'Fire III'     },  -- fire
    { id = 166, name = 'Blizzard III' },  -- ice
    { id = 171, name = 'Thunder III'  },  -- thunder
}

-- ── Detonation (the signature) ──────────────────────────────────────────────
-- On casting a listed spell, `chance`% to deal a big bonus magic hit of the
-- spell's element to the target. dmg = INT*intMult + M.Atk*mattMult + base,
-- capped. aoeRadius > 0 splashes the blast to nearby foes.
catalog.boom =
{
    chance    = 12,       -- % per cast
    intMult   = 15,
    mattMult  = 10,
    base      = 2000,
    cap       = 99999,
    aoeRadius = 0,        -- 0 = single target; e.g. 8 = blast radius (yalms)
    msg       = 'BOOM!! Your spell detonates!',
}

return catalog
