-----------------------------------
-- weapon_forge_catalog.lua
-- Data-only: defines the 14 weapon upgrade chains for two forge paths.
--
-- PATH 1 — PRIME (Ajja → Kaja → Stage-5 Relic)
--   Stage 1 (119I)   Bronze vendor (12 Beastmens Medals). Forge consumes it.
--   Stage 2 (119II)  Forge output of 119I; also sold at Silver vendor (25 Kindreds Medals).
--   Stage 3 (119III) Stage-5 Relic. Also via Relic Forge NPC (Dynamis).
--
--   Costs:
--     119I → 119II : 25× Kindreds Medal (9541)  +  HL Rank III gate
--     119II → 119III: 50× Demons Medal  (9543)  +  2000 Reforge Marks (any pool)
--                                               +  HL Rank V gate
--
-- PATH 2 — AEONIC (Malformed → 119I → 119II → Aeonic 119III)
--   Base (Malformed)  Bought from Temprix in Reisenjima (50,000 Escha Beads).
--   Stage 1 (119I)    Same Ajja/Kaja 119I weapons as the Prime path.
--   Stage 2 (119II)   Same 119II weapons as the Prime path.
--   Stage 3 (119III)  Unique Aeonic final form (Godhands / Aeneas / Sequence …).
--
--   Costs:
--     Malformed → 119I : 1×  Attestation  +  25×  Riftborn Boulder
--     119I      → 119II: 3×  Attestation  +  100× Riftborn Boulder  +  10,000 Escha Silt
--     119II     → Aeonic: 10× Attestation +  300× Riftborn Boulder  +  50,000 Escha Silt
--                                          +  20,000 Reforge Marks (any pool)
--
--   Attestations drop from Geas Fete zone bosses (Azi Dahaka / Warder of Courage).
--   Each weapon type has a specific Attestation; the aeonicCosts table maps type→id.
--
-- Reforge Marks are pooled from CharVars: RF_AF_Marks, RF_Relic_Marks, RF_Empy_Marks.
-----------------------------------
local catalog = {}

-- Forge costs (consumed from inventory).
catalog.costs =
{
    -- 119I → 119II
    toStage2 =
    {
        hlRank    = 3,
        medals    = { id = 9541, qty = 25, name = 'Kindreds Medal' },
    },
    -- 119II → 119III
    toStage3 =
    {
        hlRank       = 5,
        medals       = { id = 9543, qty = 50, name = 'Demons Medal' },
        reforgeMarks = 2000,   -- total across all three pools; drained AF→Relic→Empy
    },
}

-- Reforge-mark CharVar names, drained in order.
catalog.markVars = { 'RF_AF_Marks', 'RF_Relic_Marks', 'RF_Empy_Marks' }

-- ===================================================================
-- AEONIC FORGE COSTS
-- All three upgrade steps; attestation qty/id resolved per weapon type.
-- ===================================================================
catalog.aeonicCosts =
{
    -- Malformed → 119I
    toStage1 =
    {
        attestations     = 1,
        riftbornBoulders = 25,   -- item 4061
    },
    -- 119I → 119II
    toStage2 =
    {
        attestations     = 3,
        riftbornBoulders = 100,
        eschaSilt        = 10000,  -- charVar Escha_Silt
    },
    -- 119II → Aeonic 119III
    toStage3 =
    {
        attestations     = 10,
        riftbornBoulders = 300,
        eschaSilt        = 50000,
        reforgeMarks     = 20000,
    },
}

-- ===================================================================
-- WEAPON CHAINS
-- Each chain carries:
--   type, jobs : display metadata
--   s1/s2/s3   : Prime path (Ajja → Kaja → Stage-5 Relic)
--   aeonic     : { base, attestationId, attestationName, s3 }
--                base = Malformed weapon bought from Temprix
--                s3   = Aeonic 119III final form
--                Aeonic 119I / 119II reuse the same s1 / s2 items.
-- ===================================================================
catalog.chains =
{
    {
        type   = 'Hand-to-Hand',
        jobs   = 'MNK/PUP',
        s1     = { id = 21516, name = 'Ajja Knuckles'       },
        s2     = { id = 21515, name = 'Tokko Knuckles'      },
        s3     = { id = 21535, name = 'Varga Purnikawa'     },
        aeonic = { base = { id=29701, name='Malformed Knuckles' },
                   attestationId=1556, attestationName='Attestation of Might',
                   s3 = { id=20515, name='Godhands' } },
    },
    {
        type   = 'Dagger',
        jobs   = 'THF/BRD/DNC',
        s1     = { id = 21562, name = 'Ajja Knife'          },
        s2     = { id = 21585, name = 'Crepuscular Knife'   },
        s3     = { id = 21590, name = 'Mpu Gandring'        },
        aeonic = { base = { id=29702, name='Malformed Knife' },
                   attestationId=1557, attestationName='Attestation of Celerity',
                   s3 = { id=20594, name='Aeneas' } },
    },
    {
        type   = 'Sword',
        jobs   = 'RDM/PLD/BLU/RUN',
        s1     = { id = 21618, name = 'Ajja Sword'          },
        s2     = { id = 20673, name = 'Flametongue'         },
        s3     = { id = 21646, name = 'Caliburnus'          },
        aeonic = { base = { id=29703, name='Malformed Sword' },
                   attestationId=1558, attestationName='Attestation of Glory',
                   s3 = { id=20695, name='Sequence' } },
    },
    {
        type   = 'Great Sword',
        jobs   = 'WAR/DRK',
        s1     = { id = 21671, name = 'Ajja Claymore'       },
        s2     = { id = 21662, name = 'Raetic Algol'        },
        s3     = { id = 21653, name = 'Helheim'             },
        aeonic = { base = { id=29704, name='Malformed Claymore' },
                   attestationId=1559, attestationName='Attestation of Righteousness',
                   s3 = { id=21694, name='Lionheart' } },
    },
    {
        type   = 'Axe',
        jobs   = 'WAR/BST',
        s1     = { id = 21719, name = 'Ajja Axe'            },
        s2     = { id = 21706, name = 'Barbarity'           },
        s3     = { id = 21730, name = 'Spalirisos'          },
        aeonic = { base = { id=29705, name='Malformed Axe' },
                   attestationId=1560, attestationName='Attestation of Bravery',
                   s3 = { id=21753, name='Tri-edge' } },
    },
    {
        type   = 'Great Axe',
        jobs   = 'WAR',
        s1     = { id = 21776, name = 'Ajja Chopper'        },
        s2     = { id = 21765, name = 'Hepatizon Axe'       },
        s3     = { id = 21785, name = 'Laphria'             },
        aeonic = { base = { id=29706, name='Malformed Greataxe' },
                   attestationId=1561, attestationName='Attestation of Force',
                   s3 = { id=20843, name='Chango' } },
    },
    {
        type   = 'Scythe',
        jobs   = 'DRK',
        s1     = { id = 21827, name = 'Ajja Scythe'         },
        s2     = { id = 21815, name = 'Maliya Sickle'       },
        s3     = { id = 21837, name = 'Foenaria'            },
        aeonic = { base = { id=29707, name='Malformed Scythe' },
                   attestationId=1562, attestationName='Attestation of Vigor',
                   s3 = { id=20890, name='Anguta' } },
    },
    {
        type   = 'Polearm',
        jobs   = 'DRG',
        s1     = { id = 21880, name = 'Ajja Lance'          },
        s2     = { id = 21881, name = 'Eletta Lance'        },
        s3     = { id = 21891, name = 'Gae Buide'           },
        aeonic = { base = { id=29708, name='Malformed Lance' },
                   attestationId=1563, attestationName='Attestation of Fortitude',
                   s3 = { id=20935, name='Trishula' } },
    },
    {
        type   = 'Katana',
        jobs   = 'NIN',
        s1     = { id = 21919, name = 'Ajja Katana'         },
        s2     = { id = 21915, name = 'Koga Shinobi-Gatana' },
        s3     = { id = 21932, name = 'Dokoku'              },
        aeonic = { base = { id=29709, name='Malformed Katana' },
                   attestationId=1564, attestationName='Attestation of Legerity',
                   s3 = { id=20977, name='Heishi Shorinken' } },
    },
    {
        type   = 'Great Katana',
        jobs   = 'SAM',
        s1     = { id = 21972, name = 'Ajja Tachi'          },
        s2     = { id = 21963, name = 'Beryllium Tachi'     },
        s3     = { id = 21986, name = 'Kusanagi'            },
        aeonic = { base = { id=29710, name='Malformed Tachi' },
                   attestationId=1565, attestationName='Attestation of Decisiveness',
                   s3 = { id=21025, name='Dojikiri Yasutsuna' } },
    },
    {
        type   = 'Club',
        jobs   = 'WHM/GEO',
        s1     = { id = 22028, name = 'Ajja Rod'            },
        s2     = { id = 22030, name = 'Kaja Rod'            },
        s3     = { id = 22002, name = 'Lorg Mor'            },
        aeonic = { base = { id=29711, name='Malformed Rod' },
                   attestationId=1566, attestationName='Attestation of Sacrifice',
                   s3 = { id=21082, name='Tishtrya' } },
    },
    {
        type   = 'Staff',
        jobs   = 'BLM/SMN/SCH',
        s1     = { id = 22083, name = 'Ajja Staff'          },
        s2     = { id = 22085, name = 'Kaja Staff'          },
        s3     = { id = 22106, name = 'Opashoro'            },
        aeonic = { base = { id=29712, name='Malformed Staff' },
                   attestationId=1567, attestationName='Attestation of Virtue',
                   s3 = { id=21147, name='Khatvanga' } },
    },
    {
        type   = 'Archery',
        jobs   = 'RNG',
        s1     = { id = 22109, name = 'Ajja Bow'            },
        s2     = { id = 22126, name = 'Exalted Bow +1'      },
        s3     = { id = 22163, name = 'Pinaka'              },
        aeonic = { base = { id=29713, name='Malformed Bow' },
                   attestationId=1568, attestationName='Attestation of Transcendence',
                   s3 = { id=22117, name='Fail-not' } },
    },
    {
        type   = 'Marksmanship',
        jobs   = 'COR/RNG',
        s1     = { id = 21276, name = 'Pulfanxa'            },
        s2     = { id = 22134, name = 'Holliday'            },
        s3     = { id = 22164, name = 'Earp'                },
        aeonic = { base = { id=29714, name='Malformed Culverin' },
                   attestationId=1569, attestationName='Attestation of Harmony',
                   s3 = { id=21485, name='Fomalhaut' } },
    },
}

-- ===================================================================
-- LOOKUP TABLES (keyed by item id for fast inventory scanning)
-- ===================================================================
catalog.byId = {}
for _, chain in ipairs(catalog.chains) do
    -- Prime path scan: detect 119I and 119II weapons.
    catalog.byId[chain.s1.id] = { chain = chain, fromStage = 1, path = 'prime' }
    catalog.byId[chain.s2.id] = { chain = chain, fromStage = 2, path = 'prime' }
    -- Aeonic path scan: detect Malformed base weapon.
    if chain.aeonic then
        catalog.byId[chain.aeonic.base.id] = { chain = chain, fromStage = 0, path = 'aeonic' }
    end
end

return catalog
