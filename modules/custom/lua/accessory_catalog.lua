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
table.insert(s.ring, { id =  13564, name = 'Lightning Ring'                    , cost =  32, jobs = 'All' })  -- DPS score 11 [RARE,EX]
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
table.insert(g.waist, { id =  28461, name = 'Sekhmet Corset'                    , cost =  60, jobs = 'WHM/BLM/RDM/BRD/SMN/GEO' })  -- CASTER score 60 [RARE,EX]

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


return catalog
