-----------------------------------
-- Legendary Open World Scaling
-- Data-only tuning and exclusions.
-----------------------------------
local catalog = {}

catalog.enabled  = true
catalog.minLevel = 91
catalog.debug    = false

-- Conservative positive classification: only these proven open-world
-- progression zones are eligible. Instanced counterparts are intentionally
-- omitted. Add new zones only after checking their ordinary spawn population.
catalog.eligibleZones =
{
    -- Legacy zones that contain ordinary Apex/Locus progression camps.
    [xi.zone.BIBIKI_BAY]             = true,
    [xi.zone.PROMYVION_HOLLA]        = true,
    [xi.zone.PROMYVION_DEM]          = true,
    [xi.zone.PROMYVION_MEA]          = true,
    [xi.zone.PROMYVION_VAHZL]        = true,
    [xi.zone.BHAFLAU_THICKETS]       = true,
    [xi.zone.KING_RANPERRES_TOMB]    = true,

    -- Public Seekers of Adoulin progression zones.
    [xi.zone.RALA_WATERWAYS]         = true,
    [xi.zone.YAHSE_HUNTING_GROUNDS] = true,
    [xi.zone.CEIZAK_BATTLEGROUNDS]  = true,
    [xi.zone.FORET_DE_HENNETIEL]    = true,
    [xi.zone.YORCIA_WEALD]          = true,
    [xi.zone.MORIMAR_BASALT_FIELDS] = true,
    [xi.zone.MARJAMI_RAVINE]        = true,
    [xi.zone.KAMIHR_DRIFTS]         = true,
    [xi.zone.SIH_GATES]             = true,
    [xi.zone.MOH_GATES]             = true,
    [xi.zone.CIRDAS_CAVERNS]        = true,
    [xi.zone.DHO_GATES]             = true,
    [xi.zone.WOH_GATES]             = true,
    [xi.zone.OUTER_RAKAZNAR]        = true,
    [xi.zone.RAKAZNAR_INNER_COURT]  = true,
    [xi.zone.MOUNT_KAMIHR]          = true,

    -- Escha/Reisenjima field trash; NMs and dynamic pops are filtered at runtime.
    [xi.zone.ESCHA_ZITAH]           = true,
    [xi.zone.ESCHA_RUAUN]           = true,
    [xi.zone.REISENJIMA]            = true,
}

-- Values are minimum floors, not multipliers. Existing stronger values remain
-- unchanged, while low fixed-HP/database mobs are raised to the intended band.
-- MACC is deliberately omitted: mob magic skill already scales above level 99,
-- and adding a large flat MACC value would double-count that engine scaling.
catalog.levelProfiles =
{
    {
        minLevel = 91,
        maxLevel = 99,
        name     = 'Entry post-75',
        hpFloor  = 60000,
        modFloors =
        {
            [xi.mod.ATT]  = 600,
            [xi.mod.RATT] = 600,
            [xi.mod.DEF]  = 500,
            [xi.mod.ACC]  = 450,
            [xi.mod.RACC] = 450,
            [xi.mod.EVA]  = 400,
            [xi.mod.MEVA] = 400,
        },
    },
    {
        minLevel = 100,
        maxLevel = 109,
        name     = 'Item level entry',
        hpFloor  = 100000,
        modFloors =
        {
            [xi.mod.ATT]  = 800,
            [xi.mod.RATT] = 800,
            [xi.mod.DEF]  = 650,
            [xi.mod.ACC]  = 550,
            [xi.mod.RACC] = 550,
            [xi.mod.EVA]  = 500,
            [xi.mod.MEVA] = 500,
        },
    },
    {
        minLevel = 110,
        maxLevel = 119,
        name     = 'Mid-tier progression',
        hpFloor  = 180000,
        modFloors =
        {
            [xi.mod.ATT]  = 1100,
            [xi.mod.RATT] = 1100,
            [xi.mod.DEF]  = 850,
            [xi.mod.ACC]  = 700,
            [xi.mod.RACC] = 700,
            [xi.mod.EVA]  = 650,
            [xi.mod.MEVA] = 650,
        },
    },
    {
        minLevel = 120,
        maxLevel = 129,
        name     = 'Strong open world',
        hpFloor  = 320000,
        modFloors =
        {
            [xi.mod.ATT]  = 1500,
            [xi.mod.RATT] = 1500,
            [xi.mod.DEF]  = 1100,
            [xi.mod.ACC]  = 850,
            [xi.mod.RACC] = 850,
            [xi.mod.EVA]  = 800,
            [xi.mod.MEVA] = 800,
        },
    },
    {
        minLevel = 130,
        maxLevel = 134,
        name     = 'Capacity Point farming',
        hpFloor  = 450000,
        modFloors =
        {
            [xi.mod.ATT]  = 1800,
            [xi.mod.RATT] = 1800,
            [xi.mod.DEF]  = 1300,
            [xi.mod.ACC]  = 950,
            [xi.mod.RACC] = 950,
            [xi.mod.EVA]  = 900,
            [xi.mod.MEVA] = 900,
        },
    },
    {
        minLevel = 135,
        maxLevel = 255,
        name     = 'Elite open world',
        hpFloor  = 600000,
        modFloors =
        {
            [xi.mod.ATT]  = 2100,
            [xi.mod.RATT] = 2100,
            [xi.mod.DEF]  = 1500,
            [xi.mod.ACC]  = 1050,
            [xi.mod.RACC] = 1050,
            [xi.mod.EVA]  = 1000,
            [xi.mod.MEVA] = 1000,
        },
    },
}

-- Explicit exclusions are checked after the hard runtime exclusions.
catalog.exclusions =
{
    zoneIds    = {},
    speciesIds = {},
    poolIds    = {},
    mobIds     = {},
}

-- Override precedence:
-- mob > zone mob > zone pool > zone species > pool > species > zone default
-- > level profile. Each override is a partial patch.
catalog.speciesOverrides = {}
catalog.poolOverrides    = {}
catalog.mobOverrides     = {}

catalog.zoneOverrides =
{
    [xi.zone.RAKAZNAR_INNER_COURT] =
    {
        -- Apex Poxhound (pool 4828) is the initial owner-requested benchmark.
        -- Its level 137-139 spawns should have at least 600,000 HP.
        poolOverrides =
        {
            [4828] = { hpFloor = 600000 },
        },
    },
}

return catalog
