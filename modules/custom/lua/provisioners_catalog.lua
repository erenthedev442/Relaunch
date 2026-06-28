-----------------------------------
-- provisioners_catalog.lua
-- Config for the Provisioners' League (see ProvisionersLeague.lua) -
-- the non-combat league: fishing weigh-ins + crafting turn-ins.
--
-- Fishing points are DERIVED from the engine's own fish table
-- (xi.fishing.catchData) at load - every catchable fish scores, no
-- curation: base = skill/10 (min 1), big fish x2, legendary x10.
-- Crafting points ride the existing Crafting Exchange: every accepted
-- HQ turn-in also credits league points (marks / craftDivisor).
--
-- A weekly FEATURED FISH (deterministic ISO-week rotation over the
-- realistically-catchable pool) pays x3 - that's the tournament.
-- Weekly score (League_WeekScore) feeds the website leaderboard.
-----------------------------------
local catalog = {}

-- The League Steward, posted beside The Chronicler at Escha ZiTah.
catalog.npcPos =
{
    zone     = 'Escha_ZiTah',
    zoneId   = 210,
    x        = 29.000,
    y        = -0.500,
    z        = -30.000,
    rotation = 128,
}

-- ============================================================
-- SCORING
-- ============================================================
catalog.scoring =
{
    skillDivisor   = 10,   -- base points = max(1, floor(skillLvl / this))
    bigMult        = 2,    -- "big fish" (ruler-measured) multiplier
    legendaryMult  = 10,   -- legendary catches are league gold
    featuredMult   = 3,    -- this week's featured fish
    craftDivisor   = 10,   -- league points per Crafting Exchange turn-in = marks / this
}

-- Featured-fish eligibility: keeps the weekly target catchable by a
-- normal angler (no legendaries, sane skill band).
catalog.featured =
{
    minSkill = 15,
    maxSkill = 95,
}

-- ============================================================
-- RANKS (lifetime League_Points thresholds)
-- ============================================================
catalog.ranks =
{
    { points = 0,     label = 'Apprentice Provisioner', bonusMarks = 0    },
    { points = 750,   label = 'Journeyman Provisioner', bonusMarks = 250  },
    { points = 2500,  label = 'Expert Provisioner',     bonusMarks = 750  },
    { points = 7500,  label = 'Master Provisioner',     bonusMarks = 2000 },
    { points = 20000, label = 'Legendary Provisioner',  bonusMarks = 5000 },
}

return catalog
