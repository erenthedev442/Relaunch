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

-- Every !expcamp pack spawn. Used for two things:
--   1) OWS HP floors skip Adoulin 95/105 packs (SQL HP is the camp bar).
--   2) NO_CAPACITY_POINTS on spawn -- camp HP is too low to be a CP channel.
-- Keep in sync with modules/custom/sql/expcamp_camps.sql.
local expCampPackIds =
{
    -- 1 La Theine Grass Funguar
    17195412, 17195413, 17195414, 17195423, 17195424, 17195425,
    17195434, 17195435, 17195436, 17195437, 17195446, 17195447,
    -- 2 Konschtat Mad Sheep
    17219905, 17219928, 17219930, 17219931, 17219932, 17219963,
    17219964, 17219973, 17219974, 17219975, 17219983, 17219984,
    -- 3 Tahrongi Killer Bee
    17256626, 17256684, 17256806, 17256807, 17256808, 17256828,
    17256829, 17256846, 17256847, 17256848, 17256855, 17256866,
    -- 4 Valkurm Sand Hare
    17199409, 17199410, 17199411, 17199412, 17199481, 17199482,
    17199483, 17199484, 17199492, 17199493, 17199494, 17199495,
    -- 5 Qufim Giant Ranger / Hunter
    17293631, 17293632, 17293633, 17293634, 17293635, 17293636,
    17293637, 17293638,
    -- 6 Yuhtunga Young Opo-opo
    17281242, 17281244, 17281246, 17281247, 17281249, 17281250,
    17281253, 17281266, 17281267,
    -- 7 Yhoator Worker Crawler
    17285467, 17285468, 17285469, 17285491, 17285492, 17285497,
    17285504, 17285512, 17285530, 17285531, 17285532, 17285533,
    -- 8 Crawler's Nest Knight Crawler
    17584321, 17584322, 17584323, 17584335, 17584337, 17584338,
    17584411, 17584412, 17584413, 17584420, 17584421, 17584422,
    -- 9 Gustav Greater Gaylas
    17645569, 17645570, 17645572, 17645590, 17645591, 17645617,
    17645618, 17645619, 17645629, 17645630,
    -- 10 Kuftal Sand Lizard
    17489929, 17489930, 17490011, 17490012, 17490021,
    -- 11 Western Altepa Desert Spider
    17289229, 17289230, 17289231, 17289235, 17289242, 17289243,
    17289244, 17289245, 17289260, 17289273, 17289274, 17289275,
    -- 12 Boyahda Skimmer
    17404135, 17404137, 17404139, 17404140, 17404146, 17404147,
    17404156, 17404157, 17404163, 17404164, 17404172, 17404173,
    -- 13 Bhaflau Colibri
    16990300, 16990301, 16990302, 16990303, 16990316, 16990317,
    16990318, 16990331, 16990332, 16990333, 16990334, 16990335,
    -- 14 Zhayolm Sweeping Cluster
    17027205, 17027206, 17027299, 17027300, 17027301, 17027306,
    17027307, 17027308, 17027309, 17027314, 17027316, 17027317,
    -- 15 Misareaux Seaboard Vulture
    16879700, 16879709, 16879710, 16879711, 16879712, 16879713,
    16879714, 16879715, 16879716, 16879717, 16879718, 16879719,
    -- 16 Caedarva Marsh Murre
    17100817, 17100818, 17100826, 17100834, 17100839, 17100841,
    17100850, 17100857, 17100862, 17100864, 17100885, 17100963,
    -- 17 Ceizak Blanched Mandragora
    17846285, 17846286, 17846287, 17846288, 17846289, 17846290,
    17846301, 17846302, 17846303, 17846304, 17846305, 17846306,
    -- 18 Yorcia Corpse Flower
    17854481, 17854482, 17854483, 17854490, 17854491, 17854495, 17854496,
    17854500, 17854501, 17854502, 17854503, 17854504, 17854505, 17854506,
    17854516, 17854530, 17854623, 17854680, 17854681, 17854750,
    -- 19 Marjami Whispering Twitherym
    17866758, 17866759, 17866760, 17866761, 17866762, 17866763, 17866764,
    17866767, 17866768, 17866769, 17866771, 17866772, 17866773,
    17866861, 17866862, 17866863, 17866864, 17866865, 17866949, 17866950,
    -- 20 Gustaberg [S] Drachenlizard
    17137994, 17138023, 17138024, 17138025, 17138026, 17138027,
    17138028, 17138029, 17138030, 17138031, 17138032, 17138033, 17138034,
    -- 21 Hennetiel Scummy Slug
    17850482, 17850483, 17850484, 17850486, 17850487, 17850488, 17850489,
    17850490, 17850491, 17850493, 17850494, 17850495, 17850496, 17850498,
    17850692,
    -- 22 Kamihr Ashen Tiger
    17870997, 17870998, 17871008, 17871009, 17871010, 17871013, 17871014,
    17871019, 17871020, 17871021, 17871023, 17871024,
}

catalog.expCampMobIds = {}
for _, mobId in ipairs(expCampPackIds) do
    catalog.expCampMobIds[mobId] = true
end

catalog.exclusions =
{
    zoneIds    = {},
    speciesIds = {},
    poolIds    = {},
    mobIds     = catalog.expCampMobIds,
}

-- Override precedence:
-- mob > zone mob > zone pool > zone species > pool > species > zone default
-- > level profile. Each override is a partial patch.
catalog.speciesOverrides = {}
catalog.poolOverrides    = {}
catalog.mobOverrides     = {}

-- Abyssea field trash only (NMs stay on their mark-pop HP). Floors match
-- the 75-99 exp-camp curve so Abyssea is not a softer leveling channel.
catalog.abysseaTrashFloors =
{
    [xi.zone.ABYSSEA_KONSCHTAT]  = 10000,
    [xi.zone.ABYSSEA_TAHRONGI]   = 10000,
    [xi.zone.ABYSSEA_LA_THEINE]  = 10000,
    [xi.zone.ABYSSEA_ATTOHWA]    = 12000,
    [xi.zone.ABYSSEA_MISAREAUX]  = 12000,
    [xi.zone.ABYSSEA_VUNKERL]    = 12000,
    [xi.zone.ABYSSEA_ALTEPA]     = 30000,
    [xi.zone.ABYSSEA_ULEGUERAND] = 30000,
    [xi.zone.ABYSSEA_GRAUBERG]   = 30000,
}

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
