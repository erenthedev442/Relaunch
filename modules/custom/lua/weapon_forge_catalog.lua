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
-- PRIME is the pinnacle path: HL Legend, all five Prime Armory Trials complete,
-- 750M gil, 30k Reforge Marks, and the steepest medal cost on the server.
catalog.costs =
{
    -- 119I → 119II
    toStage2 =
    {
        hlRank    = 5,
        medals    = { id = 9541, qty = 50, name = 'Kindreds Medal' },
    },
    -- 119II → 119III  (the Prime wall)
    toStage3 =
    {
        hlRank        = 5,
        medals        = { id = 9543, qty = 100, name = 'Demons Medal' },
        reforgeMarks  = 30000,   -- total across all three pools; drained AF→Relic→Empy
        gil           = 750000000,
        requireTrials = true,    -- all of PW_Trial1_Done .. PW_Trial5_Done must be 1
    },
}

-- Prime Armory Trial completion CharVars (shared with PrimeArmory_NPC.lua).
-- The final Prime forge requires every one of these to be set.
catalog.primeTrialVars = {
    'PW_Trial1_Done', 'PW_Trial2_Done', 'PW_Trial3_Done',
    'PW_Trial4_Done', 'PW_Trial5_Done',
}

-- Reforge-mark CharVar names, drained in order.
catalog.markVars = { 'RF_AF_Marks', 'RF_Relic_Marks', 'RF_Empy_Marks' }

-- ===================================================================
-- AEONIC FORGE COSTS
-- All three upgrade steps; attestation qty/id resolved per weapon type.
-- ===================================================================
-- Aeonic is gated at HL Rank IV (Champion) throughout.
catalog.aeonicCosts =
{
    -- Malformed → 119I
    toStage1 =
    {
        hlRank           = 4,
        attestations     = 1,
        riftbornBoulders = 25,   -- item 4061
    },
    -- 119I → 119II
    toStage2 =
    {
        hlRank           = 4,
        attestations     = 3,
        riftbornBoulders = 100,
        eschaBeads       = 10000,  -- real currency escha_beads (unified Escha currency)
    },
    -- 119II → Aeonic 119III
    toStage3 =
    {
        hlRank           = 4,
        attestations     = 10,
        riftbornBoulders = 300,
        eschaBeads       = 50000,
        reforgeMarks     = 24000,
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

-- ============================================================================
-- EMPYREAN / MYTHIC / RELIC forge paths (added 2026-07-06)
-- The 119 III weapons are now forgeable. Recipes/gates match the weapon-forge
-- docs (tools/docgen/templates/weapon_forge_widget.html). Base weapons are
-- issued by the forge (their retail NM-drop sources are WIP) gated by HL rank +
-- the entry currency. Chains + per-weapon materials verified against item_basic.
-- Reforge Marks drain the shared RF_*_Marks pools (catalog.markVars).
-- ============================================================================
catalog.forgeMats = { beastcoin = 1875, riftbornBoulder = 4061, byneBill = 1455,
    silverpiece = 1453, jadeshell = 1450, pluton = 4059, imperialBronze = 2184,
    imperialSilver = 2185, imperialGold = 2187, beitetsu = 4060 }

-- Per-step: hlRank gate + material amounts. currency drained via delCurrency.
catalog.empyreanCosts =
{
    { hlRank = 3, cruor =  2000, mat = 50, beastcoin = 10 },              -- base -> 119 I
    { hlRank = 4, cruor = 10000, boulder = 300, beastcoin = 30 },         -- 119 I -> II
    { hlRank = 5, boulder = 5000, beastcoin = 50, marks = 15000 },        -- 119 II -> III
}
catalog.mythicCosts =
{
    { hlRank = 3, standing = 1000, bronze = 10 },                         -- base -> 119 I
    { hlRank = 4, standing = 3000, silver = 25, beitetsu = 300 },         -- 119 I -> II
    { hlRank = 5, gold = 5, beitetsu = 10000, marks = 20000 },            -- 119 II -> III
}
catalog.relicCosts =
{
    { hlRank = 5, byne = 100, silverpiece = 25 },                         -- base -> 119 I
    { hlRank = 5, byne = 300, jadeshell = 50, pluton = 100 },             -- 119 I -> II
    { hlRank = 5, pluton = 300, marks = 10000 },                          -- 119 II -> III (Gallimaufry omitted: absent on server)
}
-- Base provision (forge issues the base; retail NM drops are WIP).
catalog.empyreanBase = { hlRank = 3, cruor = 2000 }
catalog.mythicBase   = { hlRank = 3, standing = 1000 }
catalog.relicBase    = { hlRank = 5, byne = 100 }

catalog.empyreanChains =
{
    { type = 'Hand-to-Hand', jobs = 'MNK/PUP', name = 'Verethragna', base = 19805, s1 = 20486, s2 = 20487, s3 = 20512, mat = 2927 },
    { type = 'Dagger', jobs = 'THF/BRD/DNC', name = 'Twashtar', base = 19806, s1 = 20563, s2 = 20564, s3 = 20587, mat = 3287 },
    { type = 'Sword', jobs = 'RDM/PLD/BLU', name = 'Almace', base = 19807, s1 = 20653, s2 = 20654, s3 = 20689, mat = 3288 },
    { type = 'Great Sword', jobs = 'WAR/DRK', name = 'Caladbolg', base = 19808, s1 = 20747, s2 = 20748, s3 = 21684, mat = 2962 },
    { type = 'Axe', jobs = 'WAR/BST', name = 'Farsha', base = 19809, s1 = 20794, s2 = 20795, s3 = 21752, mat = 2963 },
    { type = 'Great Axe', jobs = 'WAR', name = 'Ukonvasara', base = 19810, s1 = 20839, s2 = 20840, s3 = 21758, mat = 2928 },
    { type = 'Scythe', jobs = 'DRK', name = 'Redemption', base = 19811, s1 = 20884, s2 = 20885, s3 = 21810, mat = 3499 },
    { type = 'Polearm', jobs = 'DRG', name = 'Rhongomiant', base = 19812, s1 = 20929, s2 = 20930, s3 = 21859, mat = 3498 },
    { type = 'Katana', jobs = 'NIN', name = 'Kannagi', base = 19813, s1 = 20974, s2 = 20975, s3 = 21908, mat = 3499 },
    { type = 'Great Katana', jobs = 'SAM', name = 'Masamune', base = 19814, s1 = 21019, s2 = 21020, s3 = 21956, mat = 3498 },
    { type = 'Club', jobs = 'WHM/GEO', name = 'Gambanteinn', base = 19815, s1 = 21064, s2 = 21065, s3 = 21079, mat = 2928 },
    { type = 'Staff', jobs = 'BLM/SMN/SCH', name = 'Hvergelmir', base = 19816, s1 = 21143, s2 = 21144, s3 = 22064, mat = 3499 },
    { type = 'Archery', jobs = 'RNG', name = 'Gandiva', base = 19817, s1 = 21213, s2 = 22116, s3 = 22130, mat = 2963 },
    { type = 'Marksmanship', jobs = 'COR/RNG', name = 'Armageddon', base = 19818, s1 = 21265, s2 = 21269, s3 = 22142, mat = 3287 },
}

catalog.mythicChains =
{
    { type = 'Hand-to-Hand', jobs = 'MNK', name = 'Glanzfaust', base = 19820, s1 = 20482, s2 = 20483, s3 = 20510 },
    { type = 'Hand-to-Hand', jobs = 'PUP', name = 'Kenkonken', base = 19836, s1 = 20484, s2 = 20485, s3 = 20511 },
    { type = 'Dagger', jobs = 'NIN', name = 'Vajra', base = 19824, s1 = 20559, s2 = 20560, s3 = 20585 },
    { type = 'Dagger', jobs = 'BRD', name = 'Carnwenhan', base = 19828, s1 = 20561, s2 = 20562, s3 = 20586 },
    { type = 'Dagger', jobs = 'DNC', name = 'Terpsichore', base = 19837, s1 = 20557, s2 = 20558, s3 = 20584 },
    { type = 'Sword', jobs = 'RDM', name = 'Murgleis', base = 19823, s1 = 20647, s2 = 20648, s3 = 20686 },
    { type = 'Sword', jobs = 'PLD', name = 'Burtgang', base = 19825, s1 = 20649, s2 = 20650, s3 = 20687 },
    { type = 'Sword', jobs = 'BLU', name = 'Tizona', base = 19834, s1 = 20651, s2 = 20652, s3 = 20688 },
    { type = 'Great Sword', jobs = 'WAR', name = 'Conqueror', base = 19819, s1 = 20837, s2 = 20838, s3 = 21757 },
    { type = 'Axe', jobs = 'WAR/BST', name = 'Aymur', base = 19827, s1 = 20792, s2 = 20793, s3 = 21751 },
    { type = 'Scythe', jobs = 'DRK', name = 'Liberator', base = 19826, s1 = 20882, s2 = 20883, s3 = 21809 },
    { type = 'Polearm', jobs = 'DRG', name = 'Ryunohige', base = 19832, s1 = 20927, s2 = 20928, s3 = 21858 },
    { type = 'Katana', jobs = 'NIN', name = 'Nagi', base = 19831, s1 = 20972, s2 = 20973, s3 = 21907 },
    { type = 'Great Katana', jobs = 'SAM', name = 'Kogarasumaru', base = 19830, s1 = 21017, s2 = 21018, s3 = 21955 },
    { type = 'Club', jobs = 'WHM', name = 'Yagrush', base = 19821, s1 = 21062, s2 = 21063, s3 = 21078 },
    { type = 'Staff', jobs = 'SMN', name = 'Nirvana', base = 19833, s1 = 21141, s2 = 21142, s3 = 22063 },
    { type = 'Staff', jobs = 'GEO', name = 'Laevateinn', base = 19822, s1 = 21139, s2 = 21140, s3 = 22062 },
    { type = 'Staff', jobs = 'SCH', name = 'Tupsimati', base = 19838, s1 = 21137, s2 = 21138, s3 = 22061 },
    { type = 'Archery', jobs = 'RNG', name = 'Gastraphetes', base = 19829, s1 = 21247, s2 = 21266, s3 = 22139 },
    { type = 'Marksmanship', jobs = 'COR', name = 'Death Penalty', base = 19835, s1 = 21263, s2 = 21268, s3 = 22141 },
}

catalog.relicChains =
{
    { type = 'Hand-to-Hand', jobs = 'MNK/PUP', name = 'Spharai', base = 19746, s1 = 20480, s2 = 20481, s3 = 20509 },
    { type = 'Dagger', jobs = 'RDM/THF/BRD', name = 'Mandau', base = 19747, s1 = 20555, s2 = 20556, s3 = 20583 },
    { type = 'Sword', jobs = 'RDM/PLD/BLU', name = 'Excalibur', base = 19748, s1 = 20645, s2 = 20646, s3 = 20685 },
    { type = 'Great Sword', jobs = 'WAR/DRK', name = 'Ragnarok', base = 19749, s1 = 20745, s2 = 20746, s3 = 21683 },
    { type = 'Axe', jobs = 'WAR/BST', name = 'Guttler', base = 19750, s1 = 20790, s2 = 20791, s3 = 21750 },
    { type = 'Great Axe', jobs = 'WAR', name = 'Bravura', base = 19751, s1 = 20835, s2 = 20836, s3 = 21756 },
    { type = 'Scythe', jobs = 'DRK', name = 'Apocalypse', base = 19753, s1 = 20880, s2 = 20881, s3 = 21808 },
    { type = 'Polearm', jobs = 'DRG', name = 'Gungnir', base = 19752, s1 = 20925, s2 = 20926, s3 = 21857 },
    { type = 'Katana', jobs = 'NIN', name = 'Kikoku', base = 19754, s1 = 20970, s2 = 20971, s3 = 21906 },
    { type = 'Great Katana', jobs = 'SAM', name = 'Amanomurakumo', base = 19755, s1 = 21015, s2 = 21016, s3 = 21954 },
    { type = 'Club', jobs = 'WHM/GEO', name = 'Mjollnir', base = 19756, s1 = 21060, s2 = 21061, s3 = 21077 },
    { type = 'Staff', jobs = 'BLM/SMN/SCH', name = 'Claustrum', base = 19757, s1 = 21135, s2 = 21136, s3 = 22060 },
    { type = 'Archery', jobs = 'RNG', name = 'Yoichinoyumi', base = 19759, s1 = 21211, s2 = 22115, s3 = 22129 },
    { type = 'Marksmanship', jobs = 'COR/RNG', name = 'Annihilator', base = 19758, s1 = 21261, s2 = 21267, s3 = 22140 },
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
