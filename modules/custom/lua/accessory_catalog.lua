-----------------------------------
-- accessory_catalog.lua
-- Endgame accessories for the Accessory NPC.
-- Covers Neck / Waist / Earring / Ring / Back.
--
-- Tiers (medal currencies, same trio as Armor / Weapons NPCs):
--   Bronze   = Beastmens Medal   (entry)
--   Silver   = Kindreds Medal    (mid)
--   Gold     = Demons Medal      (BiS endgame)
--
-- HOW THIS FILE IS MAINTAINED:
--   * Placement config (zoneId/zonePath/vendorPos/seals/goldExtraDrop) are
--     pinned constants near the top of tools/score_accessories.py; edit there
--     if you want the NPC somewhere else.
--   * Tier contents (the table.insert blocks below) are HAND-CURATED. They were
--     originally seeded from the live item DB, but this file is now the source
--     of truth and is edited in place -- auto-write is DISABLED (2026-07-10).
--   * tools/score_accessories.py is RECOMMENDATION-ONLY: it PRINTS scores and
--     will NOT overwrite this file. Same for tools/rebalance_all.bat.
-----------------------------------
local catalog = {}

-----------------------------------
-- ZONE / NPC PLACEMENT
--   Single source of truth for:
--     - Accessory_NPC.lua : override registration + NPC position
--     - docgen            : gear-vendors.md location table + zone prose
--   Lines up with the Armor / Weapons NPCs and the Hunting League hub
--   on the Escha - Zi'Tah vendor row (z = -30), so all gear vendors are
--   in one place and players don't zone-hop.
-----------------------------------
catalog.zoneId    = xi.zone.ESCHA_ZITAH
catalog.zonePath  = 'xi.zones.Escha_ZiTah'
catalog.vendorPos = { x = -9.0000, y = -0.5000, z = -30.0000, rot = 128 }

-----------------------------------
-- SEAL CURRENCY DEFINITIONS (shared with Armor / Weapons NPCs)
-----------------------------------
catalog.seals =
{
    bronze = { id = 9539, name = 'Beastmens Medal' },
    silver = { id = 9541, name = 'Kindreds Medal'  },
    gold   = { id = 9543, name = 'Demons Medal'    },
}

-- Gold-tier extra requirement: disabled. Mirrors the Armor NPC's
-- pattern — set this to { id = X, qty = N, name = '...' } if you
-- want Gold accessories to require an additional drop on top of
-- the seal cost. With nil, Gold accessories cost only the medal.
catalog.goldExtraDrop = nil

-----------------------------------
-- Helper: empty slot tables for a tier
-----------------------------------
local function emptySlots()
    return { neck = {}, waist = {}, ear = {}, ring = {}, back = {}, ammo = {} }
end

-----------------------------------
-- BRONZE TIER  (15 medals/piece)
-----------------------------------
catalog.bronze = emptySlots()
local b = catalog.bronze

-- neck
table.insert(b.neck, { id =  28393, name = 'Goetic Torque'                     , cost =  15, jobs = 'All' })  -- CASTER score 7 [EX]
table.insert(b.neck, { id =  13141, name = 'Republican Gold Medal'             , cost =  15, jobs = 'All' })  -- CASTER score 1 [EX]
table.insert(b.neck, { id =  10919, name = 'Tandem Necklace +1'                , cost =  15, jobs = 'All' })  -- TANK score 6 [RARE,EX]

-- waist
table.insert(b.waist, { id =  15942, name = 'Summoning Belt'                    , cost =  15, jobs = 'WHM/BLM/RDM/PLD/DRK/SMN/BLU/SCH/GEO/RUN' })  -- PET score 4 [RARE,EX]
table.insert(b.waist, { id =  28424, name = 'Shinjutsu-no-obi +1'               , cost =  15, jobs = 'WHM/BLM/RDM/BRD/SMN/SCH/GEO' })  -- CASTER score 4 [RARE,EX]

-- ear
table.insert(b.ear, { id =  14794, name = 'Quantzs Earring'                   , cost =  15, jobs = 'All' })  -- CASTER score 4 [RARE,EX]
table.insert(b.ear, { id =  11717, name = 'Callers Earring'                   , cost =  15, jobs = 'SMN' })  -- PET score 2 [RARE,EX]
table.insert(b.ear, { id =  11060, name = 'Evader Earring'                    , cost =  15, jobs = 'All' })  -- TANK score 4
table.insert(b.ear, { id =  11700, name = 'Gifted Earring'                    , cost =  15, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/SCH/GEO' })  -- CASTER score 2 [RARE,EX]

-- ring
table.insert(b.ring, { id =  10752, name = 'Prolix Ring'                       , cost =  15, jobs = 'All' })  -- CASTER score 5 [RARE]

-- back
table.insert(b.back, { id =  11008, name = 'Medala Cape'                       , cost =  15, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO' })  -- HEAL score 6 [RARE,EX]
table.insert(b.back, { id =  11554, name = 'Orison Cape'                       , cost =  15, jobs = 'WHM' })  -- HEAL score 6 [RARE,EX]


-----------------------------------
-- SILVER TIER  (32 medals/piece)
-----------------------------------
catalog.silver = emptySlots()
local s = catalog.silver

-- neck
table.insert(s.neck, { id =  25543, name = 'Futhark Torque'                    , cost =  32, jobs = 'RUN' })  -- TANK score 19
table.insert(s.neck, { id =  10947, name = 'Saevus Pendant'                    , cost =  32, jobs = 'WHM/BLM/SMN/PUP/SCH/GEO' })  -- CASTER score 21 [RARE]
table.insert(s.neck, { id =  11594, name = 'Estoqueurs Collar'                 , cost =  32, jobs = 'RDM' })  -- HEAL score 17 [RARE,EX]
table.insert(s.neck, { id =  15527, name = 'Praecis Gorget'                    , cost =  32, jobs = 'WAR/PLD/DRK/BST/DRG' })  -- WS score 21 [RARE,EX]
table.insert(s.neck, { id =  11619, name = 'Callers Pendant'                   , cost =  32, jobs = 'SMN' })  -- PET score 18 [RARE,EX]
table.insert(s.neck, { id =  16306, name = 'Halting Stole'                     , cost =  32, jobs = 'All' })  -- DPS score 21 [RARE,EX]
table.insert(s.neck, { id =  10946, name = 'Coatl Gorget'                      , cost =  32, jobs = 'PLD/DRK' })  -- TANK score 18 [RARE]

-- waist
table.insert(s.waist, { id =  11734, name = 'Shaolin Belt'                      , cost =  32, jobs = 'WAR/MNK/BST/NIN/PUP' })  -- DPS score 16 [RARE,EX]
table.insert(s.waist, { id =  28455, name = 'Ovate Rope'                        , cost =  32, jobs = 'WHM/BLM/RDM/BRD/RNG/NIN/SMN/BLU/PUP/SCH/GEO' })  -- HEAL score 16 [RARE]

-- ear
table.insert(s.ear, { id =  28484, name = 'Nourishing Earring'                , cost =  32, jobs = 'WHM/PLD' })  -- HEAL score 8 [RARE,EX]

-- ring
table.insert(s.ring, { id =  10784, name = 'Dhanurveda Ring'                   , cost =  32, jobs = 'All' })  -- DPS score 12 [RARE]
table.insert(s.ring, { id =  15545, name = 'Tamas Ring'                        , cost =  32, jobs = 'All' })  -- CASTER score 12 [RARE,EX]
-- Do NOT add the 6 elemental rings (13560-13565) here: HTBF trial-by-element drops.
table.insert(s.ring, { id =  10759, name = 'Aifes Annulet'                     , cost =  32, jobs = 'All' })  -- CASTER score 10 [RARE,EX]

-- back
table.insert(s.back, { id =  11555, name = 'Ferine Mantle'                     , cost =  32, jobs = 'BST' })  -- DPS score 18 [RARE,EX]
table.insert(s.back, { id =  10976, name = 'Kaikias Cape'                      , cost =  32, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO' })  -- CASTER score 18 [RARE]
table.insert(s.back, { id =  11000, name = 'Swith Cape'                        , cost =  32, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO' })  -- HEAL score 18
table.insert(s.back, { id =  28631, name = 'Conveyance Cape'                   , cost =  32, jobs = 'SMN' })  -- PET score 19 [EX]
table.insert(s.back, { id =  16203, name = 'Goetia Mantle'                     , cost =  32, jobs = 'BLM' })  -- CASTER score 18 [RARE,EX]

-- ammo
table.insert(s.ammo, { id =  21383, name = 'Eminent Sachet'                    , cost =  32, jobs = 'SMN' })  -- PET score 54 [RARE,EX]
table.insert(s.ammo, { id =  21388, name = 'Dashavatara Sachet'                , cost =  32, jobs = 'SMN' })  -- PET score 50 [RARE,EX]
table.insert(s.ammo, { id =  21393, name = 'Arasy Sachet'                      , cost =  32, jobs = 'SMN' })  -- PET score 50


-----------------------------------
-- GOLD TIER  (60 medals/piece)
-----------------------------------
catalog.gold = emptySlots()
local g = catalog.gold

-- neck
table.insert(g.neck, { id =  25460, name = 'Abyssal Bead Necklace +1'          , cost =  60, jobs = 'DRK' })  -- DPS score 97
table.insert(g.neck, { id =  26037, name = 'Moonlight Necklace'                , cost =  60, jobs = 'WAR/MNK/PLD/NIN/RUN' })  -- TANK score 72
table.insert(g.neck, { id =  26033, name = 'Moonbow Whistle +1'                , cost =  60, jobs = 'BRD' })  -- HEAL score 34
table.insert(g.neck, { id =  25419, name = 'Warriors Bead Necklace +2'         , cost =  60, jobs = 'WAR' })  -- DPS score 88
table.insert(g.neck, { id =  26016, name = 'Incanters Torque'                  , cost =  60, jobs = 'All' })  -- DPS score 50 [RARE,EX]
table.insert(g.neck, { id =  25455, name = 'Knights Bead Necklace +2'          , cost =  60, jobs = 'PLD' })  -- TANK score 70
-- net-new gold options (2026-07-06, hand-curated from score_accessories.py recommendations)
table.insert(g.neck, { id =  26086, name = 'Nicanders Necklace'                , cost =  60, jobs = 'All' })  -- DPS score 93 [RARE]
table.insert(g.neck, { id =  25437, name = 'Sorcerers Stole +2'                , cost =  60, jobs = 'BLM' })  -- CASTER score 81
table.insert(g.neck, { id =  25533, name = 'Argute Stole +2'                   , cost =  60, jobs = 'SCH' })  -- CASTER score 60
table.insert(g.neck, { id =  25443, name = 'Duelists Torque +2'                , cost =  60, jobs = 'RDM' })  -- CASTER score 60
table.insert(g.neck, { id =  25496, name = 'Dragoons Collar +1'                , cost =  60, jobs = 'DRG' })  -- DPS score 82
-- JSE +2 necks for the remaining 15 jobs (2026-07-09, report: Herdofturtles/Jamesta --
-- "+2 JSE necks missing"). The scorer only stocked the top-scoring 7; hand-added so
-- EVERY job has a purchasable +2 neck. Native shop window, so slot length is unbounded.
table.insert(g.neck, { id =  25425, name = 'Monks Nodowa +2'                   , cost =  60, jobs = 'MNK' })
table.insert(g.neck, { id =  25431, name = 'Clerics Torque +2'                 , cost =  60, jobs = 'WHM' })
table.insert(g.neck, { id =  25449, name = 'Assassins Gorget +2'               , cost =  60, jobs = 'THF' })
table.insert(g.neck, { id =  25467, name = 'Beastmaster Collar +2'             , cost =  60, jobs = 'BST' })
table.insert(g.neck, { id =  25473, name = 'Bards Charm +2'                    , cost =  60, jobs = 'BRD' })
table.insert(g.neck, { id =  25479, name = 'Scouts Gorget +2'                  , cost =  60, jobs = 'RNG' })
table.insert(g.neck, { id =  25485, name = 'Samurais Nodowa +2'                , cost =  60, jobs = 'SAM' })
table.insert(g.neck, { id =  25491, name = 'Ninja Nodowa +2'                   , cost =  60, jobs = 'NIN' })
table.insert(g.neck, { id =  25503, name = 'Summoners Collar +2'               , cost =  60, jobs = 'SMN' })
table.insert(g.neck, { id =  25509, name = 'Mirage Stole +2'                   , cost =  60, jobs = 'BLU' })
table.insert(g.neck, { id =  25515, name = 'Commodore Charm +2'                , cost =  60, jobs = 'COR' })
table.insert(g.neck, { id =  25521, name = 'Puppetmasters Collar +2'           , cost =  60, jobs = 'PUP' })
table.insert(g.neck, { id =  25527, name = 'Etoile Gorget +2'                  , cost =  60, jobs = 'DNC' })
table.insert(g.neck, { id =  25539, name = 'Bagua Charm +2'                    , cost =  60, jobs = 'GEO' })
table.insert(g.neck, { id =  25545, name = 'Futhark Torque +2'                 , cost =  60, jobs = 'RUN' })

-- waist
table.insert(g.waist, { id =  26340, name = 'Moonbow Belt'                      , cost =  60, jobs = 'MNK/PUP' })  -- DPS score 111
table.insert(g.waist, { id =  11750, name = 'Creed Baudrier'                    , cost =  60, jobs = 'PLD' })  -- TANK score 57 [RARE,EX]
table.insert(g.waist, { id =  26356, name = 'Skrymir Cord'                      , cost =  60, jobs = 'All' })  -- CASTER score 145
table.insert(g.waist, { id =  26360, name = 'Gerdr Belt'                        , cost =  60, jobs = 'WAR/MNK/RDM/THF/PLD/DRK/BST/BRD/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- DPS score 111
table.insert(g.waist, { id =  28437, name = 'Flume Belt +1'                     , cost =  60, jobs = 'WAR/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- TANK score 55 [RARE]
table.insert(g.waist, { id =  26351, name = 'Sacro Cord'                        , cost =  60, jobs = 'WHM/BLM/RDM/BLU/SCH/GEO' })  -- CASTER score 64 [RARE,EX]
-- net-new gold options (2026-07-06, hand-curated from score_accessories.py recommendations)
table.insert(g.waist, { id =  26332, name = 'Tempus Fugit +1'                   , cost =  60, jobs = 'WAR/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- DPS score 91
table.insert(g.waist, { id =  28447, name = 'Sweordfaetels +1'                  , cost =  60, jobs = 'WAR/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- DPS score 87
table.insert(g.waist, { id =  28439, name = 'Prosilio Belt +1'                  , cost =  60, jobs = 'All' })  -- WS score 67 [RARE]
-- Do NOT add 28461 Sekhmet Corset here: HTBF Ark Angels 3 drop.

-- ear
table.insert(g.ear, { id =  26078, name = 'Kyrenes Earring'                   , cost =  60, jobs = 'All' })  -- DPS score 54 [RARE]
table.insert(g.ear, { id =  28478, name = 'Etiolation Earring'                , cost =  60, jobs = 'All' })  -- TANK score 43 [RARE,EX]
table.insert(g.ear, { id =  26107, name = 'Thrud Earring'                     , cost =  60, jobs = 'WAR/PLD/DRK/BST/SAM/DRG' })  -- WS score 35 [RARE,EX]
table.insert(g.ear, { id =  28506, name = 'Andoaa Earring'                    , cost =  60, jobs = 'All' })  -- DPS score 25 [RARE,EX]
table.insert(g.ear, { id =  26079, name = 'Hypaspist Earring'                 , cost =  60, jobs = 'All' })  -- DPS score 54 [RARE]
table.insert(g.ear, { id =  28483, name = 'Cryptic Earring'                   , cost =  60, jobs = 'All' })  -- TANK score 36 [RARE,EX]
-- net-new gold options (2026-07-06, hand-curated from score_accessories.py recommendations)
table.insert(g.ear, { id =  26114, name = 'Balder Earring'                    , cost =  60, jobs = 'All' })  -- DPS score 53
table.insert(g.ear, { id =  27540, name = 'Eabani Earring'                    , cost =  60, jobs = 'All' })  -- TANK score 31 [RARE,EX]

-- ring
table.insert(g.ring, { id =  10766, name = 'Lunette Ring'                      , cost =  60, jobs = 'All' })  -- DPS score 96 [RARE]
table.insert(g.ring, { id =  28472, name = 'Freke Ring'                        , cost =  60, jobs = 'WHM/BLM/RDM/SMN/SCH/GEO' })  -- CASTER score 49 [RARE,EX]
table.insert(g.ring, { id =  26184, name = 'Stikini Ring +1'                   , cost =  60, jobs = 'All' })  -- HEAL score 63
table.insert(g.ring, { id =  14625, name = 'Evokers Ring'                      , cost =  60, jobs = 'SMN' })  -- PET score 23 [RARE,EX]
table.insert(g.ring, { id =  26189, name = 'Moonbeam Ring'                     , cost =  60, jobs = 'WAR/THF/PLD/DRK/BST/BRD/DRG/DNC/RUN' })  -- DPS score 96
table.insert(g.ring, { id =  10769, name = 'Gelatinous Ring +1'                , cost =  60, jobs = 'All' })  -- TANK score 64 [RARE,EX]
-- net-new gold options (2026-07-06, hand-curated from score_accessories.py recommendations)
table.insert(g.ring, { id =  26215, name = 'Menelauss Ring'                    , cost =  60, jobs = 'All' })  -- DPS score 96 [RARE]

-- back
table.insert(g.back, { id =  28624, name = 'Niht Mantle'                       , cost =  60, jobs = 'DRK' })  -- DPS score 80 [EX]
table.insert(g.back, { id =  28591, name = 'Aenotherus Mantle +1'              , cost =  60, jobs = 'WHM/BLM/RDM/PLD/DRK/SMN/BLU/SCH/GEO/RUN' })  -- TANK score 74
table.insert(g.back, { id =  26268, name = 'Moonbeam Cape'                     , cost =  60, jobs = 'All' })  -- TANK score 68
table.insert(g.back, { id =  15471, name = 'Merciful Cape'                     , cost =  60, jobs = 'All' })  -- DPS score 25 [RARE,EX]
table.insert(g.back, { id =  10971, name = 'Strendu Mantle'                    , cost =  60, jobs = 'WAR/PLD/DRK/BST/DRG' })  -- TANK score 73 [RARE,EX]
table.insert(g.back, { id =  28636, name = 'Bookworms Cape'                    , cost =  60, jobs = 'SCH' })  -- CASTER score 74 [EX]
-- net-new gold options (2026-07-06, hand-curated from score_accessories.py recommendations)
table.insert(g.back, { id =  28641, name = 'Vespid Mantle'                     , cost =  60, jobs = 'WAR/MNK/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- DPS score 70 [RARE,EX]
table.insert(g.back, { id =  28630, name = 'Updraft Mantle'                    , cost =  60, jobs = 'DRG' })  -- DPS score 70 [EX]


-----------------------------------
-- INFAMY TIER  (top-5-per-slot BiS + Sortie JSE +2 earrings)
--   Not sold by the Accessory NPC. Promoted to the Dungeon Infamy
--   Vendor by tools/build_infamy_top_picks.py.
-----------------------------------
catalog.infamy = emptySlots()
local inf = catalog.infamy

-- neck (top 5 by score -> Infamy Vendor)
table.insert(inf.neck, { id =  26035, name = 'Moonlight Nodowa'                  , cost = 300, jobs = 'MNK/SAM/NIN' })  -- DPS score 98

-- waist (top 5 by score -> Infamy Vendor)

-- ear (top 5 by score -> Infamy Vendor)

-- ring (top 5 by score -> Infamy Vendor)
table.insert(inf.ring, { id =  10783, name = 'Veneficium Ring'                   , cost = 300, jobs = 'All' })  -- DPS score 96 [RARE]
table.insert(inf.ring, { id =  28537, name = 'Lunette Ring +1'                   , cost = 300, jobs = 'All' })  -- DPS score 96 [RARE]

-- back (top 5 by score -> Infamy Vendor)
table.insert(inf.back, { id =  28628, name = 'Takaha Mantle'                     , cost = 300, jobs = 'SAM' })  -- DPS score 112 [EX]

-- ear (Sortie +2, one per job)



-----------------------------------
-- HUNT-VENDOR BATCH (owner 2026-07-13): Escha/Delve/Skirmish gear NOT obtainable
-- anywhere else on relaunch (exclusive). Tier = flat ilvl band:
--   gold >=116 | silver 110-115 | bronze <110 (accessories have no ilvl -> bronze).
-----------------------------------
table.insert(b.back, { id = 26275, name = "Alabaster Mantle", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.back, { id = 11004, name = "Algidus Cape", cost = 15, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO' })  -- ilvl 0
table.insert(b.back, { id = 28618, name = "Anchorets Mantle", cost = 15, jobs = 'MNK' })  -- ilvl 0
table.insert(b.back, { id = 10979, name = "Balladeers Cape", cost = 15, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO' })  -- ilvl 0
table.insert(b.back, { id = 28620, name = "Bane Cape", cost = 15, jobs = 'BLM' })  -- ilvl 0
table.insert(b.back, { id = 27600, name = "Bleating Mantle", cost = 15, jobs = 'WAR/MNK/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- ilvl 0
table.insert(b.back, { id = 10988, name = "Blithe Mantle", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.back, { id = 11576, name = "Bond Cape", cost = 15, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO' })  -- ilvl 0
table.insert(b.back, { id = 28612, name = "Buquwik Cape", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.back, { id = 28622, name = "Canny Cape", cost = 15, jobs = 'THF' })  -- ilvl 0
table.insert(b.back, { id = 10981, name = "Chela Cape", cost = 15, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO' })  -- ilvl 0
table.insert(b.back, { id = 10994, name = "Chuparrosa Mantle", cost = 15, jobs = 'DRK' })  -- ilvl 0
table.insert(b.back, { id = 26246, name = "Cichols Mantle", cost = 15, jobs = 'WAR' })  -- ilvl 0
table.insert(b.back, { id = 28642, name = "Contrivers Cape", cost = 15, jobs = 'PUP' })  -- ilvl 0
table.insert(b.back, { id = 28632, name = "Cornflower Cape", cost = 15, jobs = 'BLU' })  -- ilvl 0
table.insert(b.back, { id = 28634, name = "Dispersal Mantle", cost = 15, jobs = 'PUP' })  -- ilvl 0
table.insert(b.back, { id = 10993, name = "Drachenblut Cape", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.back, { id = 28608, name = "Earthcry Mantle", cost = 15, jobs = 'WAR/MNK/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- ilvl 0
table.insert(b.back, { id = 10990, name = "Engulfer Cape", cost = 15, jobs = 'WAR/MNK/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- ilvl 0
table.insert(b.back, { id = 28599, name = "Engulfer Cape +1", cost = 15, jobs = 'WAR/MNK/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- ilvl 0
table.insert(b.back, { id = 28638, name = "Evasionists Cape", cost = 15, jobs = 'RUN' })  -- ilvl 0
table.insert(b.back, { id = 28589, name = "Felicitas Cape +1", cost = 15, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO' })  -- ilvl 0
table.insert(b.back, { id = 11010, name = "Feline Mantle", cost = 15, jobs = 'WAR/MNK/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- ilvl 0
table.insert(b.back, { id = 11005, name = "Fierabrass Mantle", cost = 15, jobs = 'WAR/PLD' })  -- ilvl 0
table.insert(b.back, { id = 28592, name = "Forban Cape +1", cost = 15, jobs = 'RNG/COR' })  -- ilvl 0
table.insert(b.back, { id = 28593, name = "Fugacity Mantle +1", cost = 15, jobs = 'WAR/MNK/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- ilvl 0
table.insert(b.back, { id = 28621, name = "Ghostfyre Cape", cost = 15, jobs = 'RDM' })  -- ilvl 0
table.insert(b.back, { id = 28633, name = "Gunslingers Cape", cost = 15, jobs = 'COR' })  -- ilvl 0
table.insert(b.back, { id = 11012, name = "Gwyddions Cape", cost = 15, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO' })  -- ilvl 0
table.insert(b.back, { id = 28610, name = "Ik Cape", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.back, { id = 27622, name = "Impassive Mantle", cost = 15, jobs = 'WAR/PLD/DRK/BST/DRG' })  -- ilvl 0
table.insert(b.back, { id = 28614, name = "Iximulew Cape", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.back, { id = 28588, name = "Karagoz Mantle +1", cost = 15, jobs = 'PUP' })  -- ilvl 0
table.insert(b.back, { id = 28613, name = "Kayapa Cape", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.back, { id = 28603, name = "Kumbira Cape", cost = 15, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO' })  -- ilvl 0
table.insert(b.back, { id = 28637, name = "Lifestream Cape", cost = 15, jobs = 'GEO' })  -- ilvl 0
table.insert(b.back, { id = 27608, name = "Lupine Cape", cost = 15, jobs = 'WAR/MNK/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- ilvl 0
table.insert(b.back, { id = 28627, name = "Lutian Cape", cost = 15, jobs = 'RNG' })  -- ilvl 0
table.insert(b.back, { id = 28617, name = "Maulers Mantle", cost = 15, jobs = 'WAR' })  -- ilvl 0
table.insert(b.back, { id = 10987, name = "Meanagh Cape", cost = 15, jobs = 'MNK/THF/BST/RNG/NIN/BLU/COR/PUP/DNC/RUN' })  -- ilvl 0
table.insert(b.back, { id = 28597, name = "Meanagh Cape +1", cost = 15, jobs = 'MNK/THF/BST/RNG/NIN/BLU/COR/PUP/DNC/RUN' })  -- ilvl 0
table.insert(b.back, { id = 27596, name = "Mecistopins Mantle", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.back, { id = 28619, name = "Mending Cape", cost = 15, jobs = 'WHM' })  -- ilvl 0
table.insert(b.back, { id = 10978, name = "Misuuchi Kappa", cost = 15, jobs = 'MNK/SAM/NIN' })  -- ilvl 0
table.insert(b.back, { id = 10980, name = "Mollusca Mantle", cost = 15, jobs = 'WAR/MNK/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- ilvl 0
table.insert(b.back, { id = 10985, name = "Moondoe Mantle", cost = 15, jobs = 'WAR/MNK/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- ilvl 0
table.insert(b.back, { id = 28595, name = "Moondoe Mantle +1", cost = 15, jobs = 'WAR/MNK/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- ilvl 0
table.insert(b.back, { id = 28604, name = "Mubvumbamiri Mantle", cost = 15, jobs = 'WAR/MNK/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- ilvl 0
table.insert(b.back, { id = 26276, name = "Murky Mantle", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.back, { id = 26274, name = "Null Shawl", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.back, { id = 10986, name = "Oretanias Cape", cost = 15, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO' })  -- ilvl 0
table.insert(b.back, { id = 28596, name = "Oretanias Cape +1", cost = 15, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO' })  -- ilvl 0
table.insert(b.back, { id = 28640, name = "Pahtli Cape", cost = 15, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO' })  -- ilvl 0
table.insert(b.back, { id = 28625, name = "Pastoralists Mantle", cost = 15, jobs = 'BST' })  -- ilvl 0
table.insert(b.back, { id = 11003, name = "Prodigious Mantle", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.back, { id = 10991, name = "Rancorous Mantle", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.back, { id = 28643, name = "Refraction Cape", cost = 15, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO' })  -- ilvl 0
table.insert(b.back, { id = 27621, name = "Relucent Cape", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.back, { id = 28639, name = "Repulse Mantle", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.back, { id = 28626, name = "Rhapsodes Cape", cost = 15, jobs = 'BRD' })  -- ilvl 0
table.insert(b.back, { id = 10977, name = "Romanus Cape", cost = 15, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO' })  -- ilvl 0
table.insert(b.back, { id = 26270, name = "Sacro Mantle", cost = 15, jobs = 'MNK/THF/BST/NIN/PUP/DNC' })  -- ilvl 0
table.insert(b.back, { id = 28605, name = "Samanisi Cape", cost = 15, jobs = 'SMN' })  -- ilvl 0
table.insert(b.back, { id = 28609, name = "Savior Mantle", cost = 15, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO' })  -- ilvl 0
table.insert(b.back, { id = 11013, name = "Taubran Cape", cost = 15, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO' })  -- ilvl 0
table.insert(b.back, { id = 10989, name = "Tempered Cape", cost = 15, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO/RUN' })  -- ilvl 0
table.insert(b.back, { id = 28598, name = "Tempered Cape +1", cost = 15, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO/RUN' })  -- ilvl 0
table.insert(b.back, { id = 11006, name = "Thall Mantle", cost = 15, jobs = 'WAR/MNK/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- ilvl 0
table.insert(b.back, { id = 28635, name = "Toetapper Mantle", cost = 15, jobs = 'DNC' })  -- ilvl 0
table.insert(b.back, { id = 28615, name = "Toro Cape", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.back, { id = 28611, name = "Tuilha Cape", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.back, { id = 10992, name = "Vassals Mantle", cost = 15, jobs = 'WAR/MNK/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- ilvl 0
table.insert(b.back, { id = 28590, name = "Vates Cape +1", cost = 15, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO' })  -- ilvl 0
table.insert(b.back, { id = 28594, name = "Vellaunus Mantle +1", cost = 15, jobs = 'MNK/RDM/THF/BST/RNG/NIN/DRG/COR/PUP/DNC/RUN' })  -- ilvl 0
table.insert(b.back, { id = 10982, name = "Vimukti Mantle", cost = 15, jobs = 'WAR/MNK/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- ilvl 0
table.insert(b.back, { id = 28623, name = "Weard Mantle", cost = 15, jobs = 'PLD' })  -- ilvl 0
table.insert(b.back, { id = 28629, name = "Yokaze Mantle", cost = 15, jobs = 'NIN' })  -- ilvl 0
table.insert(b.back, { id = 10995, name = "Zaffre Cape", cost = 15, jobs = 'BLU' })  -- ilvl 0
table.insert(b.neck, { id = 28357, name = "Acesos Choker +1", cost = 15, jobs = 'WHM' })  -- ilvl 0
table.insert(b.neck, { id = 28394, name = "Analgesia Torque", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.neck, { id = 28355, name = "Ardor Pendant +1", cost = 15, jobs = 'WAR/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- ilvl 0
table.insert(b.neck, { id = 28402, name = "Asperity Necklace", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.neck, { id = 28385, name = "Atzintli Necklace", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.neck, { id = 10937, name = "Calcitrant Stole", cost = 15, jobs = 'MNK/RDM/THF/BST/RNG/NIN/DRG/COR/PUP/DNC/RUN' })  -- ilvl 0
table.insert(b.neck, { id = 28350, name = "Cloud Hairpin", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.neck, { id = 28351, name = "Cloud Hairpin +1", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.neck, { id = 28363, name = "Coatl Gorget +1", cost = 15, jobs = 'PLD/DRK' })  -- ilvl 0
table.insert(b.neck, { id = 28386, name = "Cuamiz Collar", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.neck, { id = 27506, name = "Defiant Collar", cost = 15, jobs = 'WAR/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- ilvl 0
table.insert(b.neck, { id = 27507, name = "Deviant Necklace", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.neck, { id = 10939, name = "Dualism Collar", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.neck, { id = 28362, name = "Dualism Collar +1", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.neck, { id = 28401, name = "Eddy Necklace", cost = 15, jobs = 'WHM/BLM/RDM/PLD/DRK/SMN/BLU/SCH/GEO/RUN' })  -- ilvl 0
table.insert(b.neck, { id = 28356, name = "Eidolon Pendant +1", cost = 15, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO' })  -- ilvl 0
table.insert(b.neck, { id = 28397, name = "Ensnaring Torque", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.neck, { id = 28398, name = "Farr Torque", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.neck, { id = 10928, name = "Ganeshas Mala", cost = 15, jobs = 'DRK/SAM/DRG' })  -- ilvl 0
table.insert(b.neck, { id = 28366, name = "Gaudryi Necklace", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.neck, { id = 28395, name = "Hamrammr Torque", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.neck, { id = 10938, name = "Houyis Gorget", cost = 15, jobs = 'WAR/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- ilvl 0
table.insert(b.neck, { id = 26043, name = "Hoxne Torque", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.neck, { id = 28384, name = "Huani Collar", cost = 15, jobs = 'MNK/RDM/THF/BST/RNG/NIN/DRG/COR/PUP/DNC/RUN' })  -- ilvl 0
table.insert(b.neck, { id = 28381, name = "Imbodla Necklace", cost = 15, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/SCH/GEO' })  -- ilvl 0
table.insert(b.neck, { id = 28403, name = "Inquisitor Bead Necklace", cost = 15, jobs = 'MNK/RDM/THF/BST/RNG/NIN/DRG/COR/PUP/DNC/RUN' })  -- ilvl 0
table.insert(b.neck, { id = 10959, name = "Inquisitors Chain", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.neck, { id = 28380, name = "Iqabi Necklace", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.neck, { id = 10397, name = "Ishtars Collar", cost = 15, jobs = 'WAR/MNK/THF/BST/BRD/RNG/SAM/NIN/DRG/COR/PUP/DNC' })  -- ilvl 0
table.insert(b.neck, { id = 10934, name = "Justiciars Torque", cost = 15, jobs = 'MNK/THF/DRK/BST/SAM/DRG/DNC/RUN' })  -- ilvl 0
table.insert(b.neck, { id = 28358, name = "Katipo Charm +1", cost = 15, jobs = 'WAR/PLD/DRK/BST/SAM/NIN/DRG' })  -- ilvl 0
table.insert(b.neck, { id = 28360, name = "Lacono Necklace +1", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.neck, { id = 10395, name = "Lasaia Pendant", cost = 15, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/SCH/GEO' })  -- ilvl 0
table.insert(b.neck, { id = 28399, name = "Melioration Torque", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.neck, { id = 10958, name = "Nefarious Collar", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.neck, { id = 28365, name = "Nefarious Collar +1", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.neck, { id = 28400, name = "Ocachi Gorget", cost = 15, jobs = 'WAR/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- ilvl 0
table.insert(b.neck, { id = 10394, name = "Orunmilas Torque", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.neck, { id = 28383, name = "Pentalagus Charm", cost = 15, jobs = 'THF' })  -- ilvl 0
table.insert(b.neck, { id = 10960, name = "Phalaina Locket", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.neck, { id = 28387, name = "Quanpur Necklace", cost = 15, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO/RUN' })  -- ilvl 0
table.insert(b.neck, { id = 25415, name = "Republican Platinum Medal", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.neck, { id = 10396, name = "Rioters Collar", cost = 15, jobs = 'WAR/PLD/DRK/BST/SAM/NIN' })  -- ilvl 0
table.insert(b.neck, { id = 28364, name = "Saevus Pendant +1", cost = 15, jobs = 'WHM/BLM/SMN/PUP/SCH/GEO' })  -- ilvl 0
table.insert(b.neck, { id = 27516, name = "Satlada Necklace", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.neck, { id = 28359, name = "Shifting Necklace +1", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.neck, { id = 26041, name = "Sroda Necklace", cost = 15, jobs = 'WHM/RDM' })  -- ilvl 0
table.insert(b.neck, { id = 10957, name = "Stoicheion Medal", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.neck, { id = 28396, name = "Sverrir Torque", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.neck, { id = 28388, name = "Tlamiztli Collar", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.neck, { id = 10398, name = "Weike Torque", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.neck, { id = 10936, name = "Wiglen Gorget", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.waist, { id = 28435, name = "Acerbic Sash +1", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.waist, { id = 28426, name = "Acipayam Belt", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.waist, { id = 26344, name = "Artemiss Quiver", cost = 15, jobs = 'RNG' })  -- ilvl 0
table.insert(b.waist, { id = 10829, name = "Artful Belt", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.waist, { id = 10830, name = "Artful Belt +1", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.waist, { id = 10840, name = "Aswang Sash", cost = 15, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/SCH/GEO' })  -- ilvl 0
table.insert(b.waist, { id = 28434, name = "Austerity Belt +1", cost = 15, jobs = 'WHM/BLM/RDM/PLD/DRK/SMN/BLU/SCH/GEO/RUN' })  -- ilvl 0
table.insert(b.waist, { id = 28433, name = "Belisamas Rope +1", cost = 15, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/SCH/GEO' })  -- ilvl 0
table.insert(b.waist, { id = 10820, name = "Bishops Sash", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.waist, { id = 10842, name = "Bougonia Rope", cost = 15, jobs = 'WHM/BLM/BRD/SMN/PUP/SCH/GEO' })  -- ilvl 0
table.insert(b.waist, { id = 10832, name = "Carriers Sash", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.waist, { id = 10824, name = "Casso Sash", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.waist, { id = 10844, name = "Caudata Belt", cost = 15, jobs = 'WAR/MNK/RDM/THF/PLD/DRK/BST/BRD/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- ilvl 0
table.insert(b.waist, { id = 28460, name = "Cetl Belt", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.waist, { id = 28450, name = "Chaac Belt", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.waist, { id = 10825, name = "Chiners Belt", cost = 15, jobs = 'WAR/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- ilvl 0
table.insert(b.waist, { id = 28438, name = "Chiners Belt +1", cost = 15, jobs = 'WAR/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- ilvl 0
table.insert(b.waist, { id = 26345, name = "Chrono Quiver", cost = 15, jobs = 'RNG' })  -- ilvl 0
table.insert(b.waist, { id = 28459, name = "Chuqaba Belt", cost = 15, jobs = 'WAR/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- ilvl 0
table.insert(b.waist, { id = 10823, name = "Cimmerian Sash", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.waist, { id = 26365, name = "Cornelias Belt", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.waist, { id = 10814, name = "Corvax Sash", cost = 15, jobs = 'MNK/WHM/BLM/RDM/PLD/BRD/RNG/SMN/BLU/PUP/SCH/GEO/RUN' })  -- ilvl 0
table.insert(b.waist, { id = 10845, name = "Elanid Belt", cost = 15, jobs = 'THF/RNG/COR' })  -- ilvl 0
table.insert(b.waist, { id = 28414, name = "Engraved Belt", cost = 15, jobs = 'WAR/MNK/THF/BST/NIN/DNC/RUN' })  -- ilvl 0
table.insert(b.waist, { id = 28422, name = "Famine Sash", cost = 15, jobs = 'MNK/WHM/BLM/RDM/PLD/BRD/RNG/SMN/BLU/PUP/SCH/GEO/RUN' })  -- ilvl 0
table.insert(b.waist, { id = 28431, name = "Flax Sash", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.waist, { id = 10819, name = "Flume Belt", cost = 15, jobs = 'WAR/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- ilvl 0
table.insert(b.waist, { id = 28452, name = "Fucho-No-Obi", cost = 15, jobs = 'MNK/WHM/BLM/RDM/PLD/BRD/RNG/SMN/BLU/PUP/SCH/GEO/RUN' })  -- ilvl 0
table.insert(b.waist, { id = 28453, name = "Gevaudan Belt", cost = 15, jobs = 'WAR/PLD/DRK/BST/DRG' })  -- ilvl 0
table.insert(b.waist, { id = 10816, name = "Glassblowers Belt", cost = 15, jobs = 'WAR/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- ilvl 0
table.insert(b.waist, { id = 10822, name = "Harfners Sash", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.waist, { id = 28462, name = "Hurchlan Sash", cost = 15, jobs = 'MNK/THF/BST/RNG/NIN/BLU/COR/PUP/DNC/RUN' })  -- ilvl 0
table.insert(b.waist, { id = 28418, name = "Incarnation Sash", cost = 15, jobs = 'BST/DRG/SMN/PUP' })  -- ilvl 0
table.insert(b.waist, { id = 28451, name = "Isa Belt", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.waist, { id = 10846, name = "Istio Belt", cost = 15, jobs = 'WAR/PLD/DRK/BST/DRG' })  -- ilvl 0
table.insert(b.waist, { id = 28458, name = "Jaqij Sash", cost = 15, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/SCH/GEO' })  -- ilvl 0
table.insert(b.waist, { id = 28456, name = "Kasiri Belt", cost = 15, jobs = 'MNK/WHM/RDM/THF/BST/BRD/RNG/SAM/NIN/BLU/COR/DNC/RUN' })  -- ilvl 0
table.insert(b.waist, { id = 28457, name = "Kuku Stone", cost = 15, jobs = 'BST/DRG/SMN/PUP' })  -- ilvl 0
table.insert(b.waist, { id = 26358, name = "Ligeia Sash", cost = 15, jobs = 'SMN' })  -- ilvl 0
table.insert(b.waist, { id = 10833, name = "Maniacus Sash", cost = 15, jobs = 'WHM/BLM/BRD/SMN/PUP/SCH/GEO' })  -- ilvl 0
table.insert(b.waist, { id = 26367, name = "Null Belt", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.waist, { id = 26363, name = "Obstinate Sash", cost = 15, jobs = 'WHM/RDM/BRD/SCH' })  -- ilvl 0
table.insert(b.waist, { id = 28442, name = "Olseni Belt", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.waist, { id = 10821, name = "Olympus Sash", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.waist, { id = 10839, name = "Othila Sash", cost = 15, jobs = 'WHM/BLM/RDM/SMN/SCH/GEO' })  -- ilvl 0
table.insert(b.waist, { id = 10831, name = "Paewr Belt", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.waist, { id = 10841, name = "Panthalassa Sash", cost = 15, jobs = 'MNK/THF/RNG/NIN/BLU/COR/DNC/RUN' })  -- ilvl 0
table.insert(b.waist, { id = 10838, name = "Patentia Sash", cost = 15, jobs = 'WAR/BLM/THF/DRK/BST/RNG/NIN/DRG/PUP/DNC/SCH' })  -- ilvl 0
table.insert(b.waist, { id = 10815, name = "Phasmida Belt", cost = 15, jobs = 'WAR/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- ilvl 0
table.insert(b.waist, { id = 26366, name = "Platinum Moogle Belt", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.waist, { id = 10827, name = "Prosilio Belt", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.waist, { id = 26346, name = "Quelling Bolt Quiver", cost = 15, jobs = 'RNG' })  -- ilvl 0
table.insert(b.waist, { id = 26325, name = "Refoccilation Stone", cost = 15, jobs = 'WHM/BLM/RDM/BRD/SMN/SCH/GEO' })  -- ilvl 0
table.insert(b.waist, { id = 28421, name = "Rumination Sash", cost = 15, jobs = 'MNK/WHM/BLM/RDM/PLD/BRD/RNG/SMN/BLU/PUP/SCH/GEO/RUN' })  -- ilvl 0
table.insert(b.waist, { id = 28461, name = "Sekhmet Corset", cost = 15, jobs = 'WHM/BLM/RDM/BRD/SMN/GEO' })  -- ilvl 0
table.insert(b.waist, { id = 10835, name = "Slipor Sash", cost = 15, jobs = 'WHM/BLM/RDM/BRD/SMN/SCH/GEO' })  -- ilvl 0
table.insert(b.waist, { id = 26364, name = "Sroda Belt", cost = 15, jobs = 'PLD/RUN' })  -- ilvl 0
table.insert(b.waist, { id = 28436, name = "Sveltesse Gouriz +1", cost = 15, jobs = 'MNK/WHM/RDM/THF/BST/BRD/RNG/SAM/NIN/BLU/COR/DNC/RUN' })  -- ilvl 0
table.insert(b.waist, { id = 26362, name = "Tellen Belt", cost = 15, jobs = 'RNG/COR' })  -- ilvl 0
table.insert(b.waist, { id = 10834, name = "Wanion Belt", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.waist, { id = 10828, name = "Windbuffet Belt", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.waist, { id = 28440, name = "Windbuffet Belt +1", cost = 15, jobs = 'All' })  -- ilvl 0
table.insert(b.waist, { id = 10826, name = "Witful Belt", cost = 15, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/SCH/GEO' })  -- ilvl 0
table.insert(b.waist, { id = 28443, name = "Yamabuki-No-Obi", cost = 15, jobs = 'MNK/WHM/BLM/RDM/PLD/BRD/RNG/SMN/BLU/PUP/SCH/GEO/RUN' })  -- ilvl 0
table.insert(b.waist, { id = 26343, name = "Yoichis Quiver", cost = 15, jobs = 'RNG/SAM' })  -- ilvl 0
table.insert(b.waist, { id = 28463, name = "Zorans Belt", cost = 15, jobs = 'WAR/PLD/DRK/BST/DRG' })  -- ilvl 0

return catalog
