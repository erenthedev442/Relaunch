-----------------------------------
-- weapon_forge_catalog.lua
-- Data-only: defines the 14 weapon upgrade chains (119I → 119II → 119III).
--
-- STAGES
--   Stage 1 (119I)  -- Entry endgame. Obtainable from the Bronze weapon vendor
--                      (12 Beastmens Medals). The forge consumes this weapon.
--   Stage 2 (119II) -- Mid endgame. Forge output of 119I; also sold at the
--                      Silver vendor (25 Kindreds Medals) as a shortcut.
--   Stage 3 (119III)-- Final form (Stage-5 Relic). Forge output of 119II; also
--                      obtainable via the Relic Forge NPC (Dynamis path).
--
-- FORGE COSTS
--   119I → 119II : 25x Kindreds Medal (9541)  +  HL Rank III gate
--   119II → 119III: 50x Demons Medal  (9543)  +  2000 Reforge Marks (any pool)
--                                              +  HL Rank V gate
--
-- Reforge Marks are pooled from three CharVars: RF_AF_Marks, RF_Relic_Marks,
-- RF_Empy_Marks. The NPC drains whichever pools have balance in that order.
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

-- Weapon forge chains.  One chain per weapon skill; each stage entry carries
-- the item id and a short display label for customMenu.
catalog.chains =
{
    {
        type  = 'Hand-to-Hand',
        jobs  = 'MNK/PUP',
        s1    = { id = 21516, name = 'Ajja Knuckles'       },
        s2    = { id = 21515, name = 'Tokko Knuckles'      },
        s3    = { id = 21535, name = 'Varga Purnikawa'     },
    },
    {
        type  = 'Dagger',
        jobs  = 'THF/BRD/DNC',
        s1    = { id = 21562, name = 'Ajja Knife'          },
        s2    = { id = 21585, name = 'Crepuscular Knife'   },
        s3    = { id = 21590, name = 'Mpu Gandring'        },
    },
    {
        type  = 'Sword',
        jobs  = 'RDM/PLD/BLU/RUN',
        s1    = { id = 21618, name = 'Ajja Sword'          },
        s2    = { id = 20673, name = 'Flametongue'         },
        s3    = { id = 21646, name = 'Caliburnus'          },
    },
    {
        type  = 'Great Sword',
        jobs  = 'WAR/DRK',
        s1    = { id = 21671, name = 'Ajja Claymore'       },
        s2    = { id = 21662, name = 'Raetic Algol'        },
        s3    = { id = 21653, name = 'Helheim'             },
    },
    {
        type  = 'Axe',
        jobs  = 'WAR/BST',
        s1    = { id = 21719, name = 'Ajja Axe'            },
        s2    = { id = 21706, name = 'Barbarity'           },
        s3    = { id = 21730, name = 'Spalirisos'          },
    },
    {
        type  = 'Great Axe',
        jobs  = 'WAR',
        s1    = { id = 21776, name = 'Ajja Chopper'        },
        s2    = { id = 21765, name = 'Hepatizon Axe'       },
        s3    = { id = 21785, name = 'Laphria'             },
    },
    {
        type  = 'Scythe',
        jobs  = 'DRK',
        s1    = { id = 21827, name = 'Ajja Scythe'         },
        s2    = { id = 21815, name = 'Maliya Sickle'       },
        s3    = { id = 21837, name = 'Foenaria'            },
    },
    {
        type  = 'Polearm',
        jobs  = 'DRG',
        s1    = { id = 21880, name = 'Ajja Lance'          },
        s2    = { id = 21881, name = 'Eletta Lance'        },
        s3    = { id = 21891, name = 'Gae Buide'           },
    },
    {
        type  = 'Katana',
        jobs  = 'NIN',
        s1    = { id = 21919, name = 'Ajja Katana'         },
        s2    = { id = 21915, name = 'Koga Shinobi-Gatana' },
        s3    = { id = 21932, name = 'Dokoku'              },
    },
    {
        type  = 'Great Katana',
        jobs  = 'SAM',
        s1    = { id = 21972, name = 'Ajja Tachi'          },
        s2    = { id = 21963, name = 'Beryllium Tachi'     },
        s3    = { id = 21986, name = 'Kusanagi'            },
    },
    {
        type  = 'Club',
        jobs  = 'WHM/GEO',
        s1    = { id = 22028, name = 'Ajja Rod'            },
        s2    = { id = 22030, name = 'Kaja Rod'            },
        s3    = { id = 22002, name = 'Lorg Mor'            },
    },
    {
        type  = 'Staff',
        jobs  = 'BLM/SMN/SCH',
        s1    = { id = 22083, name = 'Ajja Staff'          },
        s2    = { id = 22085, name = 'Kaja Staff'          },
        s3    = { id = 22106, name = 'Opashoro'            },
    },
    {
        type  = 'Archery',
        jobs  = 'RNG',
        s1    = { id = 22109, name = 'Ajja Bow'            },
        s2    = { id = 22126, name = 'Exalted Bow +1'      },
        s3    = { id = 22163, name = 'Pinaka'              },
    },
    {
        type  = 'Marksmanship',
        jobs  = 'COR/RNG',
        s1    = { id = 21276, name = 'Pulfanxa'            },
        s2    = { id = 22134, name = 'Holliday'            },
        s3    = { id = 22164, name = 'Earp'                },
    },
}

-- Build lookup tables keyed by item id for fast inventory scanning.
catalog.byId = {}
for _, chain in ipairs(catalog.chains) do
    catalog.byId[chain.s1.id] = { chain = chain, fromStage = 1 }
    catalog.byId[chain.s2.id] = { chain = chain, fromStage = 2 }
end

return catalog
