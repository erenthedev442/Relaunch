-----------------------------------
-- armor_catalog.lua
-- Endgame armor for the Armor NPC.
-- Covers main armor slots: Head / Body / Hands / Legs / Feet.
--
-- Tiers (medal currencies, same trio as the Weapons NPC):
--   Bronze   = Beastmens Medal   (entry ilvl 119)
--   Silver   = Kindreds Medal    (HQ +1 / +2 augmented gear)
--   Gold     = Demons Medal      (BiS endgame: Su5 / Sortie / Carmine +1 / +3)
--                                 (Nyame moved to the Infamy Vendor - only
--                                  earnable by clearing dungeons.)
--                                 (item 9543 stack bumped to 99 via
--                                  modules/custom/sql/stackable_medals.sql)
--
-- Optional Gold-tier extra requirement: catalog.goldExtraDrop. Currently
-- nil, so Gold pieces cost just the seal. Set it to a {id, qty, name}
-- table to re-enable an extra drop universally. Individual rows can
-- still override via a per-row `drop = {...}` field.
--
-- HOW TO ADD GEAR:
--   table.insert(catalog.<tier>.<slot>, {
--       id   = xi.item.SOME_CONSTANT  -- or raw numeric ID
--       name = 'Display Name'
--       cost = N                       -- seals required
--       drop = { id = X, qty = N }     -- OPTIONAL: extra drop item required
--       jobs = 'WAR/PLD/...'
--   })
--
-- FORCED ADDS (pinned in tools/score_armor.py via FORCED_INCLUDE so the scorer
-- KEEPS them on every regen -- a plain table.insert HERE is WIPED by the next
-- re-score, so new pins MUST go in FORCED_INCLUDE, not in this file):
--   Malignance Gold set on the Armor NPC: Chapeau (23732), Tabard (23733),
--   Gloves (23734), Tights (23735), Boots (23736) -- the FULL 5-piece set. All
--   score into the gold band but fall below its per-slot top-N, so they need
--   pinning. (Gloves were on NO vendor until 2026-07-08 -- an earlier note wrongly
--   said "Infamy Vendor"; added to gold/hands FORCED_INCLUDE to complete the set.)
-----------------------------------
local catalog = {}

-----------------------------------
-- ZONE / NPC PLACEMENT
--   Single source of truth for:
--     - Armor_NPC.lua : override registration + NPC position
--     - docgen        : gear-vendors.md location table + zone name in prose
-----------------------------------
catalog.zoneId    = xi.zone.ESCHA_ZITAH
catalog.zonePath  = 'xi.zones.Escha_ZiTah'
catalog.vendorPos = { x =  -3.0000, y = -0.5000, z = -30.0000, rot = 128 }

-----------------------------------
-- SEAL CURRENCY DEFINITIONS (same as Weapons NPC)
-----------------------------------
-- All three are orphan currency items in item_basic.sql (no current drop
-- source) - perfect for an exclusive-to-Hunting-League currency loop.
-- Raw IDs are used because xi.item.* enum entries don't exist for these.
catalog.seals =
{
    bronze = { id = 9539, name = "Beastmens Medal" },  -- formerly Beastmen's Seal
    silver = { id = 9541, name = "Kindreds Medal"  },  -- formerly Kindred's Seal
    gold   = { id = 9543, name = "Demons Medal"    },  -- formerly Abdhaljs Seal
}

-- Gold-tier extra requirement: disabled. Set to a table like
--   { id = xi.item.RIFTBORN_BOULDER, qty = 1, name = 'Riftborn Boulder' }
-- to re-enable an extra drop on top of the Gold seal cost. With nil/absent,
-- Gold-tier items cost just the seal - no extra drop, no `*` marker in the
-- menu, no warning admonition in the docs.
catalog.goldExtraDrop = nil

-----------------------------------
-- Helper: empty slot tables for a tier
-----------------------------------
local function emptySlots()
    return { head = {}, body = {}, hands = {}, legs = {}, feet = {}, shields = {} }
end

-----------------------------------
-- BRONZE TIER  (entry-level ilvl 119)
-----------------------------------
-----------------------------------
-- TIER CONTENTS  (HAND-CURATED; score_armor.py is recommendation-only, auto-write disabled 2026-07-10)
--   Role-balanced top ~10 per tier-slot, expanded as needed
--   to guarantee >= 2 options per job per (tier, slot).
--   To regenerate after edits to weights or new DB content:
--     python tools/score_armor.py
-----------------------------------

-- BRONZE TIER
catalog.bronze = emptySlots()
local b = catalog.bronze

-- Head (10 picks, scored highest first; Angantyr Beret removed 2026-07-11 --
-- sold by Zurim/Domain QM, medal-vendor exclusivity)
table.insert(b.head, { id = 27720, name = "Umbani Cap", cost = 12, jobs = 'MNK/THF/RNG/NIN/BLU/COR/PUP/DNC/RUN' })  -- TANK score 198
table.insert(b.head, { id = 27724, name = "Qaaxo Mask", cost = 12, jobs = 'MNK/THF/RNG/NIN/BLU/COR/PUP/DNC/RUN' })  -- TANK score 189
table.insert(b.head, { id = 27775, name = "Nahtirah Hat", cost = 12, jobs = 'WHM/BLM/RDM/BRD/SMN/SCH/GEO' })  -- CASTER score 118
table.insert(b.head, { id = 27725, name = "Artsieq Hat", cost = 12, jobs = 'WHM/BLM/RDM/BRD/SMN/SCH/GEO' })  -- DPS score 99

-- Body (12 picks, scored highest first)

-- Hands (10 picks, scored highest first)
table.insert(b.hands, { id = 28009, name = "Onimusha-No-Kote", cost = 12, jobs = 'MNK/SAM/NIN' })  -- DPS score 199
table.insert(b.hands, { id = 27096, name = "Counts Cuffs", cost = 12, jobs = 'MNK/SAM/NIN/PUP' })  -- TANK score 195
table.insert(b.hands, { id = 28016, name = "Qaaxo Mitaines", cost = 12, jobs = 'MNK/THF/RNG/NIN/BLU/COR/PUP/DNC/RUN' })  -- TANK score 190
table.insert(b.hands, { id = 28015, name = "Xaddi Gauntlets", cost = 12, jobs = 'WAR/PLD/DRK/BST/SAM/DRG' })  -- TANK score 190
table.insert(b.hands, { id = 28013, name = "Hegira Wristbands", cost = 12, jobs = 'MNK/THF/RNG/NIN/BLU/COR/DNC/RUN' })  -- TANK score 187

-- Legs (12 picks, scored highest first)
table.insert(b.legs, { id = 28154, name = "Weatherspoon Pants +1", cost = 12, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO/RUN' })  -- TANK score 195
table.insert(b.legs, { id = 28155, name = "Scufflers Cosciales", cost = 12, jobs = 'WAR/PLD/DRK/SAM/DRG' })  -- DPS score 173
table.insert(b.legs, { id = 25853, name = "Querkening Brais", cost = 12, jobs = 'WHM/BLM/RDM/BRD/SMN/SCH/GEO' })  -- DPS score 171
table.insert(b.legs, { id = 28174, name = "Theurgists Slacks", cost = 12, jobs = 'WHM/BLM/SMN/PUP/SCH/GEO' })  -- CASTER score 159

-- Feet (11 picks, scored highest first)
table.insert(b.feet, { id = 28286, name = "Ostro Greaves", cost = 12, jobs = 'WAR/PLD/DRK/BST/DRG' })  -- DPS score 189
table.insert(b.feet, { id = 28280, name = "Sokushitsu Sune-Ate", cost = 12, jobs = 'MNK/SAM/NIN' })  -- TANK score 185
table.insert(b.feet, { id = 28287, name = "Durgai Leggings", cost = 12, jobs = 'MNK/THF/BST/NIN/PUP/DNC/RUN' })  -- DPS score 184
table.insert(b.feet, { id = 28310, name = "Vanir Boots", cost = 12, jobs = 'WAR/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- DPS score 181
table.insert(b.feet, { id = 28296, name = "Artsieq Boots", cost = 12, jobs = 'WHM/BLM/RDM/BRD/SMN/SCH/GEO' })  -- DPS score 105

-- Shields (1 picks, scored highest first)


-- SILVER TIER
catalog.silver = emptySlots()
local s = catalog.silver

-- Head (11 picks, scored highest first)
table.insert(s.head, { id = 26702, name = "Gavialis Helm", cost = 25, jobs = 'WAR/PLD/DRK/BST/SAM/NIN/DRG' })  -- TANK score 248
table.insert(s.head, { id = 26721, name = "Rabid Visor", cost = 25, jobs = 'WAR/RDM/PLD/DRK/BST/RNG/SAM/DRG/BLU/RUN' })  -- TANK score 246
table.insert(s.head, { id = 24274, name = "Amin Turban", cost = 25, jobs = 'WAR/MNK/WHM/BLM/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/SMN/BLU/COR/PUP/DNC/SCH/GEO/RUN' })  -- TANK score 237
table.insert(s.head, { id = 27710, name = "Sahip Helm", cost = 25, jobs = 'WAR/PLD/DRK/BST/SAM/DRG' })  -- TANK score 228
table.insert(s.head, { id = 25654, name = "Welkin Crown", cost = 25, jobs = 'WHM/BLM/RDM/BRD/SMN/SCH/GEO' })  -- CASTER score 208

-- Body (7 picks, scored highest first; Valorous Mail removed 2026-07-11 --
-- sold by Zurim/Domain QM, medal-vendor exclusivity)
table.insert(s.body, { id = 27887, name = "Vanir Cotehardie", cost = 25, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO/RUN' })  -- TANK score 244
table.insert(s.body, { id = 27888, name = "Kyujutsugi", cost = 25, jobs = 'RNG/SAM' })  -- DPS score 211
table.insert(s.body, { id = 26970, name = "Lapidary Tunic", cost = 25, jobs = 'MNK/THF/RNG/NIN/BLU/COR/DNC/RUN' })  -- TANK score 204

-- Hands (11 picks, scored highest first; Herculean Gloves removed 2026-07-11 --
-- sold by Zurim/Domain QM, medal-vendor exclusivity)

-- Legs (11 picks, scored highest first; Herculean Trousers + Chironic Hose
-- removed 2026-07-11 -- sold by Zurim/Domain QM, medal-vendor exclusivity)
table.insert(s.legs, { id = 28152, name = "Gorney Brayettes +1", cost = 25, jobs = 'WAR/PLD/DRK/BST/SAM/DRG' })  -- TANK score 248
table.insert(s.legs, { id = 27324, name = "Gyve Trousers", cost = 25, jobs = 'WHM/BLM/RDM/BRD/RNG/NIN/SMN/BLU/PUP/SCH/GEO' })  -- TANK score 235

-- Feet (9 picks, scored highest first; Herculean Boots removed 2026-07-11 --
-- sold by Zurim/Domain QM, medal-vendor exclusivity)

-- Shields (3 picks, scored highest first)
table.insert(s.shields, { id = 28648, name = "Priwen", cost = 25, jobs = 'PLD' })  -- TANK score 150
table.insert(s.shields, { id = 28649, name = "Rinda Shield", cost = 25, jobs = 'WAR/PLD/DRK' })  -- TANK score 126


-- GOLD TIER
catalog.gold = emptySlots()
local g = catalog.gold

-- Head (12 picks, scored highest first)
table.insert(g.head, { id = 25600, name = "Maiitsoh Haube", cost = 50, jobs = 'WAR/PLD/DRK/BST/SAM/NIN/DRG' })  -- DPS score 305

-- Body (13 picks, scored highest first)
table.insert(g.body, { id = 23798, name = "Crepuscular Mail", cost = 50, jobs = 'WAR/PLD/DRK/BST/SAM/DRG' })  -- TANK score 463
table.insert(g.body, { id = 27857, name = "Respite Cloak", cost = 50, jobs = 'MNK/WHM/BLM/RDM/PLD/BRD/RNG/SMN/BLU/PUP/SCH/GEO/RUN' })  -- TANK score 451
table.insert(g.body, { id = 25708, name = "Gyve Doublet", cost = 50, jobs = 'WHM/BLM/RDM/BRD/RNG/NIN/SMN/BLU/PUP/SCH/GEO' })  -- TANK score 276

-- Hands (10 picks, scored highest first)

-- Legs (12 picks, scored highest first)
table.insert(g.legs, { id = 24131, name = "Revelation Brais", cost = 50, jobs = 'WAR/BRD/NIN' })  -- TANK score 438

-- Feet (12 picks, scored highest first)

-- Shields (2 picks, scored highest first)
table.insert(g.shields, { id = 26487, name = "Sacro Bulwark", cost = 50, jobs = 'WAR/RDM/PLD/BST' })  -- TANK score 227


-- INFAMY TIER  (top-5-per-slot; promoted to the Dungeon Infamy
--               Vendor by tools/build_infamy_top_picks.py. Inert here:
--               the Armor NPC only sells bronze/silver/gold.)
catalog.infamy = emptySlots()
local inf = catalog.infamy

-- Head (top 5 by score -> Infamy Vendor)
table.insert(inf.head, { id = 24182, name = "Clemency Somen", cost = 500, jobs = 'RNG/SAM/DRG/COR' })  -- DPS score 434
table.insert(inf.head, { id = 24166, name = "Magnificent Crown", cost = 500, jobs = 'MNK/THF/BST/PUP/DNC' })  -- DPS score 416

-- Body (top 5 by score -> Infamy Vendor)

-- Hands (top 5 by score -> Infamy Vendor)
table.insert(inf.hands, { id = 24188, name = "Clemency Kote", cost = 500, jobs = 'RNG/SAM/DRG/COR' })  -- DPS score 428
table.insert(inf.hands, { id = 24128, name = "Revelation Gauntlets", cost = 500, jobs = 'WAR/BRD/NIN' })  -- DPS score 424

-- Legs (top 5 by score -> Infamy Vendor)

-- Feet (top 5 by score -> Infamy Vendor)
table.insert(inf.feet, { id = 24178, name = "Magnificent Sollerets", cost = 500, jobs = 'MNK/THF/BST/PUP/DNC' })  -- DPS score 394

-- Shields (top 5 by score -> Infamy Vendor)
table.insert(inf.shields, { id = 26400, name = "Culminus", cost = 500, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/SCH/GEO' })  -- CASTER score 368
table.insert(inf.shields, { id = 26403, name = "Srivatsa", cost = 500, jobs = 'PLD' })  -- TANK score 357


return catalog
