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
    chance    = 15,       -- % per cast (base; raised to abilities.ignite.boostChance during Ignite)
    intMult   = 20,
    mattMult  = 12,
    base      = 3000,
    cap       = 99999,    -- engine damage display ceiling
    aoeRadius = 0,        -- 0 = single target; e.g. 8 = blast radius (yalms)
    msg       = 'BOOM!! Your spell detonates!',
}

-- ── Signature abilities (chat commands; client can't add JA buttons) ─────────
-- The avatar/Blood-Pact buttons are inert, so abilities are delivered as
-- commands (!overload, !ignite), gated on Boom = MAIN job, with charVar
-- cooldowns (os.time). Logic lives in BoomJob.lua (xi.boomJob.*).
catalog.abilities =
{
    -- !overload — Astral-Flow-style ultimate: one massive detonation on your
    -- target (+ blast), on a long cooldown.
    overload =
    {
        cd        = 240,                 -- seconds
        mult      = 5,                   -- x a normal detonation
        aoeRadius = 12,                  -- blast radius (yalms)
        element   = xi.element.FIRE,     -- damage element of the blast
        cdVar     = 'Boom_Overload_CD',
        msg       = 'OVERLOAD!! You unleash a cataclysmic blast!',
    },
    -- !ignite — coat your staff in volatile energy: a self enspell + a window
    -- where your spells detonate far more often.
    ignite =
    {
        cd           = 90,               -- seconds
        duration     = 60,               -- seconds (enspell + boosted-detonation window)
        enspell      = xi.effect.ENFIRE, -- elemental melee add (visible buff)
        enspellPower = 60,
        boostChance  = 45,               -- detonation % while Ignite is up
        untilVar     = 'Boom_IgniteUntil',
        cdVar        = 'Boom_Ignite_CD',
        msg          = 'IGNITE!! Your staff blazes -- spells now detonate readily!',
    },
}

return catalog
