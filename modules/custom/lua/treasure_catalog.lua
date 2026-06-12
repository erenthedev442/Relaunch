-----------------------------------
-- treasure_catalog.lua
-- Config for Treasure Hunting (see TreasureHunt.lua).
--
-- Hunting League kills can shake loose a TREASURE MAP pointing at one
-- of the classic overworld zones. Travel there and !dig: your first
-- dig anchors the strongbox somewhere within seedRing of where you
-- stand (so it is always on reachable ground), then every dig gives
-- temperature + compass feedback until you close within successRadius.
-- The box pays marks, gil, and real augment catalysts - the world
-- tour feeds the augment economy.
-----------------------------------
local catalog = {}

-- Map drop roll, made after each Hunting League kill (only when the
-- player does NOT already hold a map): chance = base + perTier * tier.
catalog.drop =
{
    basePct    = 8,
    perTierPct = 2,    -- T5 kill = 18%
}

-- Kill tier -> map tier (1..3).
catalog.mapTierForKillTier = { 1, 1, 2, 2, 3 }

catalog.mapNames =
{
    [1] = 'Tattered Treasure Map',
    [2] = 'Weathered Treasure Map',
    [3] = 'Pristine Treasure Map',
}

-- Where maps can point. Zone ids resolve from the engine enum so a
-- typo fails loudly at load, not silently at runtime.
catalog.zones =
{
    { id = xi.zone.VALKURM_DUNES,         label = 'Valkurm Dunes'         },
    { id = xi.zone.BUBURIMU_PENINSULA,    label = 'Buburimu Peninsula'    },
    { id = xi.zone.QUFIM_ISLAND,          label = 'Qufim Island'          },
    { id = xi.zone.BEAUCEDINE_GLACIER,    label = 'Beaucedine Glacier'    },
    { id = xi.zone.BATALLIA_DOWNS,        label = 'Batallia Downs'        },
    { id = xi.zone.ROLANBERRY_FIELDS,     label = 'Rolanberry Fields'     },
    { id = xi.zone.SAUROMUGUE_CHAMPAIGN,  label = 'Sauromugue Champaign'  },
    { id = xi.zone.TAHRONGI_CANYON,       label = 'Tahrongi Canyon'       },
    { id = xi.zone.KONSCHTAT_HIGHLANDS,   label = 'Konschtat Highlands'   },
    { id = xi.zone.LA_THEINE_PLATEAU,     label = 'La Theine Plateau'     },
    { id = xi.zone.PASHHOW_MARSHLANDS,    label = 'Pashhow Marshlands'    },
    { id = xi.zone.MERIPHATAUD_MOUNTAINS, label = 'Meriphataud Mountains' },
    { id = xi.zone.JUGNER_FOREST,         label = 'Jugner Forest'         },
    { id = xi.zone.EASTERN_ALTEPA_DESERT, label = 'Eastern Altepa Desert' },
}

-- Dig mini-game tuning.
catalog.dig =
{
    cooldownSec   = 5,
    seedRingMin   = 35.0,   -- strongbox lands this far from your FIRST dig...
    seedRingMax   = 70.0,   -- ...anchored to ground you can clearly stand on
    successRadius = 12.0,   -- dig within this of the box = found
    -- Temperature feedback bands (2D distance, walked in order).
    bands =
    {
        { dist = 25,  text = 'SCORCHING! It must be right here!'      },
        { dist = 45,  text = 'Hot! Very close now.'                   },
        { dist = 80,  text = 'Warm. Getting closer.'                  },
        { dist = 140, text = 'Cool... a fair walk yet.'               },
        { dist = 1e9, text = 'Freezing cold. The mark is far away.'   },
    },
}

-- Strongbox payout by map tier. Catalysts are drawn at random from
-- the augment catalog's item pool (the same catalysts mobs drop).
catalog.loot =
{
    [1] = { marks = 250,  gil = 25000,  catalysts = 1, announce = false },
    [2] = { marks = 600,  gil = 75000,  catalysts = 2, announce = false },
    [3] = { marks = 1500, gil = 200000, catalysts = 4, announce = true  },
}

-- Marks paid per catalyst that could not fit in a full inventory.
catalog.fullInventoryMarks = 100

return catalog
