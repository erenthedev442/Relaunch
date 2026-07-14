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
-- Onimusha-No-Kote (28009) REMOVED 2026-07-13 (single-source: added to
-- Shadow Lord HTBF pool in commit f753d47641, so vendor row is the duplicate).
table.insert(b.hands, { id = 27096, name = "Counts Cuffs", cost = 12, jobs = 'MNK/SAM/NIN/PUP' })  -- TANK score 195
table.insert(b.hands, { id = 28016, name = "Qaaxo Mitaines", cost = 12, jobs = 'MNK/THF/RNG/NIN/BLU/COR/PUP/DNC/RUN' })  -- TANK score 190
table.insert(b.hands, { id = 28015, name = "Xaddi Gauntlets", cost = 12, jobs = 'WAR/PLD/DRK/BST/SAM/DRG' })  -- TANK score 190
table.insert(b.hands, { id = 28013, name = "Hegira Wristbands", cost = 12, jobs = 'MNK/THF/RNG/NIN/BLU/COR/DNC/RUN' })  -- TANK score 187

-- Legs (12 picks, scored highest first)
-- Weatherspoon Pants +1 (28154) was misplaced HERE using `s.legs` in the bronze
-- block (silver `s` isn't declared until line 129) -- crashed armor_catalog on
-- every deploy since 2026-07-13, taking Armor_NPC.lua down with it. Moved to
-- the silver.legs block below.
table.insert(b.legs, { id = 28155, name = "Scufflers Cosciales", cost = 12, jobs = 'WAR/PLD/DRK/SAM/DRG' })  -- DPS score 173
table.insert(b.legs, { id = 25853, name = "Querkening Brais", cost = 12, jobs = 'WHM/BLM/RDM/BRD/SMN/SCH/GEO' })  -- DPS score 171
table.insert(b.legs, { id = 28174, name = "Theurgists Slacks", cost = 12, jobs = 'WHM/BLM/SMN/PUP/SCH/GEO' })  -- CASTER score 159

-- Feet (11 picks, scored highest first)
-- Ostro Greaves (28286) REMOVED 2026-07-13 (single-source: added to
-- Trial by Wind HTBF pool in commit f753d47641, so vendor row is the duplicate).
table.insert(b.feet, { id = 28280, name = "Sokushitsu Sune-Ate", cost = 12, jobs = 'MNK/SAM/NIN' })  -- TANK score 185
table.insert(b.feet, { id = 28287, name = "Durgai Leggings", cost = 12, jobs = 'MNK/THF/BST/NIN/PUP/DNC/RUN' })  -- DPS score 184
-- Vanir Boots (28310) REMOVED 2026-07-13 (single-source: added to
-- Celestial Nexus HTBF pool in commit f753d47641, so vendor row is the duplicate).
table.insert(b.feet, { id = 28296, name = "Artsieq Boots", cost = 12, jobs = 'WHM/BLM/RDM/BRD/SMN/SCH/GEO' })  -- DPS score 105

-- Shields (1 picks, scored highest first)


-- SILVER TIER
catalog.silver = emptySlots()
local s = catalog.silver

-- Head (11 picks, scored highest first)
table.insert(s.head, { id = 26702, name = "Gavialis Helm", cost = 25, jobs = 'WAR/PLD/DRK/BST/SAM/NIN/DRG' })  -- TANK score 248
table.insert(s.head, { id = 26721, name = "Rabid Visor", cost = 25, jobs = 'WAR/RDM/PLD/DRK/BST/RNG/SAM/DRG/BLU/RUN' })  -- TANK score 246
table.insert(s.head, { id = 24274, name = "Amin Turban", cost = 25, jobs = 'WAR/MNK/WHM/BLM/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/SMN/BLU/COR/PUP/DNC/SCH/GEO/RUN' })  -- TANK score 237
-- Sahip Helm (27710) REMOVED 2026-07-13 (single-source: added to
-- Puppet in Peril HTBF pool in commit f753d47641, so vendor row is the duplicate).
table.insert(s.head, { id = 25654, name = "Welkin Crown", cost = 25, jobs = 'WHM/BLM/RDM/BRD/SMN/SCH/GEO' })  -- CASTER score 208

-- Body (7 picks, scored highest first; Valorous Mail removed 2026-07-11 --
-- sold by Zurim/Domain QM, medal-vendor exclusivity)
-- Vanir Cotehardie (27887) REMOVED 2026-07-13 (single-source: added to
-- Celestial Nexus HTBF pool in commit f753d47641, so vendor row is the duplicate).
-- Kyujutsugi (27888) REMOVED 2026-07-13 (single-source: added to
-- Divine Might HTBF pool in commit f753d47641, so vendor row is the duplicate).
table.insert(s.body, { id = 26970, name = "Lapidary Tunic", cost = 25, jobs = 'MNK/THF/RNG/NIN/BLU/COR/DNC/RUN' })  -- TANK score 204

-- Hands (11 picks, scored highest first; Herculean Gloves removed 2026-07-11 --
-- sold by Zurim/Domain QM, medal-vendor exclusivity)

-- Legs (11 picks, scored highest first; Herculean Trousers + Chironic Hose
-- removed 2026-07-11 -- sold by Zurim/Domain QM, medal-vendor exclusivity)
table.insert(s.legs, { id = 28152, name = "Gorney Brayettes +1", cost = 25, jobs = 'WAR/PLD/DRK/BST/SAM/DRG' })  -- TANK score 248
table.insert(s.legs, { id = 28154, name = "Weatherspoon Pants +1", cost = 25, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO/RUN' })  -- TANK score 195

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
table.insert(g.body, { id = 27857, name = "Respite Cloak", cost = 50, jobs = 'MNK/WHM/BLM/RDM/PLD/BRD/RNG/SMN/BLU/PUP/SCH/GEO/RUN' })  -- TANK score 451

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



-----------------------------------
-- HUNT-VENDOR BATCH (owner 2026-07-13): Escha/Delve/Skirmish gear NOT obtainable
-- anywhere else on relaunch (exclusive). Tier = flat ilvl band:
--   gold >=116 | silver 110-115 | bronze <110 (accessories have no ilvl -> bronze).
-----------------------------------
table.insert(s.body, { id = 27895, name = "Karieyh Haubert +1", cost = 25, jobs = 'WAR/PLD/DRK/BST/SAM/DRG' } )  -- ilvl 109
table.insert(b.body, { id = 27826, name = "Maxixi Casaque", cost = 12, jobs = 'DNC' })  -- ilvl 109
table.insert(s.body, { id = 27897, name = "Orvail Robe +1", cost = 25, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO/RUN' } )  -- ilvl 109
table.insert(s.body, { id = 27896, name = "Thurandaut Tabard +1", cost = 25, jobs = 'MNK/THF/RNG/NIN/BLU/COR/PUP/DNC/RUN' } )  -- ilvl 109
table.insert(b.body, { id = 27907, name = "Gorney Haubert", cost = 12, jobs = 'WAR/PLD/DRK/BST/SAM/DRG' })  -- ilvl 106
table.insert(b.body, { id = 27908, name = "Shneddick Tabard", cost = 12, jobs = 'MNK/THF/RNG/NIN/BLU/COR/PUP/DNC/RUN' })  -- ilvl 106
table.insert(b.body, { id = 27909, name = "Weatherspoon Robe", cost = 12, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO/RUN' })  -- ilvl 106
table.insert(b.body, { id = 27925, name = "Karieyh Haubert", cost = 12, jobs = 'WAR/PLD/DRK/BST/SAM/DRG' })  -- ilvl 100
table.insert(b.body, { id = 27922, name = "Orvail Robe", cost = 12, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO/RUN' })  -- ilvl 100
table.insert(b.body, { id = 27924, name = "Thurandaut Tabard", cost = 12, jobs = 'MNK/THF/RNG/NIN/BLU/COR/PUP/DNC/RUN' })  -- ilvl 100
table.insert(s.feet, { id = 28320, name = "Karieyh Sollerets +1", cost = 25, jobs = 'WAR/PLD/DRK/BST/SAM/DRG' } )  -- ilvl 109
table.insert(b.feet, { id = 28242, name = "Maxixi Toe Shoes", cost = 12, jobs = 'DNC' })  -- ilvl 109
table.insert(s.feet, { id = 28322, name = "Orvail Souliers +1", cost = 25, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO/RUN' } )  -- ilvl 109
table.insert(s.feet, { id = 28321, name = "Thurandaut Boots +1", cost = 25, jobs = 'MNK/THF/RNG/NIN/BLU/COR/PUP/DNC/RUN' } )  -- ilvl 109
table.insert(b.feet, { id = 28304, name = "Litany Clogs", cost = 12, jobs = 'WHM' })  -- ilvl 107
table.insert(b.feet, { id = 28343, name = "Chocaliztli Boots", cost = 12, jobs = 'WAR/PLD/DRK/BST/SAM/DRG' })  -- ilvl 106
table.insert(b.feet, { id = 28327, name = "Gorney Sollerets", cost = 12, jobs = 'WAR/PLD/DRK/BST/SAM/DRG' })  -- ilvl 106
table.insert(b.feet, { id = 28328, name = "Shneddick Boots", cost = 12, jobs = 'MNK/THF/RNG/NIN/BLU/COR/PUP/DNC/RUN' })  -- ilvl 106
table.insert(b.feet, { id = 28329, name = "Weatherspoon Souliers", cost = 12, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO/RUN' })  -- ilvl 106
table.insert(b.feet, { id = 28345, name = "Karieyh Sollerets", cost = 12, jobs = 'WAR/PLD/DRK/BST/SAM/DRG' })  -- ilvl 100
table.insert(b.feet, { id = 28342, name = "Orvail Souliers", cost = 12, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO/RUN' })  -- ilvl 100
table.insert(b.feet, { id = 28344, name = "Thurandaut Boots", cost = 12, jobs = 'MNK/THF/RNG/NIN/BLU/COR/PUP/DNC/RUN' })  -- ilvl 100
table.insert(b.hands, { id = 28027, name = "Boor Bracelets", cost = 12, jobs = 'WAR/MNK/RDM/THF/PLD/DRK/BST/BRD/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- ilvl 109
table.insert(s.hands, { id = 28042, name = "Karieyh Moufles +1", cost = 25, jobs = 'WAR/PLD/DRK/BST/SAM/DRG' } )  -- ilvl 109
table.insert(b.hands, { id = 27962, name = "Maxixi Bangles", cost = 12, jobs = 'DNC' })  -- ilvl 109
table.insert(s.hands, { id = 28044, name = "Orvail Cuffs +1", cost = 25, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO/RUN' } )  -- ilvl 109
table.insert(s.hands, { id = 28043, name = "Thurandaut Gloves +1", cost = 25, jobs = 'MNK/THF/RNG/NIN/BLU/COR/PUP/DNC/RUN' } )  -- ilvl 109
table.insert(b.hands, { id = 28026, name = "Aiwon Gauntlets", cost = 12, jobs = 'PLD/DRK' })  -- ilvl 107
table.insert(b.hands, { id = 28046, name = "Gorney Moufles", cost = 12, jobs = 'WAR/PLD/DRK/BST/SAM/DRG' })  -- ilvl 106
table.insert(b.hands, { id = 28062, name = "Quauhpilli Gloves", cost = 12, jobs = 'WHM/BLM/RDM/BRD/SMN/SCH/GEO' })  -- ilvl 106
table.insert(b.hands, { id = 28047, name = "Shneddick Gloves", cost = 12, jobs = 'MNK/THF/RNG/NIN/BLU/COR/PUP/DNC/RUN' })  -- ilvl 106
table.insert(b.hands, { id = 28048, name = "Weatherspoon Cuffs", cost = 12, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO/RUN' })  -- ilvl 106
table.insert(b.hands, { id = 28065, name = "Karieyh Moufles", cost = 12, jobs = 'WAR/PLD/DRK/BST/SAM/DRG' })  -- ilvl 100
table.insert(b.hands, { id = 28061, name = "Orvail Cuffs", cost = 12, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO/RUN' })  -- ilvl 100
table.insert(b.hands, { id = 28064, name = "Thurandaut Gloves", cost = 12, jobs = 'MNK/THF/RNG/NIN/BLU/COR/PUP/DNC/RUN' })  -- ilvl 100
table.insert(s.head, { id = 27752, name = "Karieyh Morion +1", cost = 25, jobs = 'WAR/PLD/DRK/BST/SAM/DRG' } )  -- ilvl 109
table.insert(b.head, { id = 27682, name = "Maxixi Tiara", cost = 12, jobs = 'DNC' })  -- ilvl 109
table.insert(s.head, { id = 27754, name = "Orvail Corona +1", cost = 25, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO/RUN' } )  -- ilvl 109
table.insert(s.head, { id = 27753, name = "Thurandaut Chapeau +1", cost = 25, jobs = 'MNK/THF/RNG/NIN/BLU/COR/PUP/DNC/RUN' } )  -- ilvl 109
table.insert(b.head, { id = 27735, name = "Enedron Glasses", cost = 12, jobs = 'All' })  -- ilvl 107
table.insert(b.head, { id = 27780, name = "Chocaliztli Mask", cost = 12, jobs = 'MNK/THF/RNG/NIN/BLU/COR/PUP/DNC/RUN' })  -- ilvl 106
table.insert(b.head, { id = 27761, name = "Gorney Morion", cost = 12, jobs = 'WAR/PLD/DRK/BST/SAM/DRG' })  -- ilvl 106
table.insert(b.head, { id = 27779, name = "Quauhpilli Helm", cost = 12, jobs = 'WAR/PLD/DRK/BST/SAM/DRG' })  -- ilvl 106
table.insert(b.head, { id = 27762, name = "Shneddick Chapeau", cost = 12, jobs = 'MNK/THF/RNG/NIN/BLU/COR/PUP/DNC/RUN' })  -- ilvl 106
table.insert(b.head, { id = 27763, name = "Weatherspoon Corona", cost = 12, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO/RUN' })  -- ilvl 106
table.insert(b.head, { id = 27781, name = "Xux Hat", cost = 12, jobs = 'WHM/BLM/RDM/BRD/SMN/SCH/GEO' })  -- ilvl 106
table.insert(b.head, { id = 27785, name = "Karieyh Morion", cost = 12, jobs = 'WAR/PLD/DRK/BST/SAM/DRG' })  -- ilvl 100
table.insert(b.head, { id = 27782, name = "Orvail Corona", cost = 12, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO/RUN' })  -- ilvl 100
table.insert(b.head, { id = 27784, name = "Thurandaut Chapeau", cost = 12, jobs = 'MNK/THF/RNG/NIN/BLU/COR/PUP/DNC/RUN' })  -- ilvl 100
table.insert(s.legs, { id = 28182, name = "Karieyh Brayettes +1", cost = 25, jobs = 'WAR/PLD/DRK/BST/SAM/DRG' } )  -- ilvl 109
table.insert(b.legs, { id = 28109, name = "Maxixi Tights", cost = 12, jobs = 'DNC' })  -- ilvl 109
table.insert(s.legs, { id = 28184, name = "Orvail Pants +1", cost = 25, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO/RUN' } )  -- ilvl 109
table.insert(s.legs, { id = 28183, name = "Thurandaut Tights +1", cost = 25, jobs = 'MNK/THF/RNG/NIN/BLU/COR/PUP/DNC/RUN' } )  -- ilvl 109
table.insert(b.legs, { id = 28165, name = "Laktisma Hose", cost = 12, jobs = 'MNK/SAM/NIN' })  -- ilvl 107
table.insert(b.legs, { id = 28188, name = "Gorney Brayettes", cost = 12, jobs = 'WAR/PLD/DRK/BST/SAM/DRG' })  -- ilvl 106
table.insert(b.legs, { id = 28189, name = "Shneddick Tights", cost = 12, jobs = 'MNK/THF/RNG/NIN/BLU/COR/PUP/DNC/RUN' })  -- ilvl 106
table.insert(b.legs, { id = 28190, name = "Weatherspoon Pants", cost = 12, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO/RUN' })  -- ilvl 106
table.insert(b.legs, { id = 28201, name = "Xux Trousers", cost = 12, jobs = 'MNK/THF/RNG/NIN/BLU/COR/PUP/DNC/RUN' })  -- ilvl 106
table.insert(b.legs, { id = 28205, name = "Karieyh Brayettes", cost = 12, jobs = 'WAR/PLD/DRK/BST/SAM/DRG' })  -- ilvl 100
table.insert(b.legs, { id = 28203, name = "Orvail Pants", cost = 12, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO/RUN' })  -- ilvl 100
table.insert(b.legs, { id = 28204, name = "Thurandaut Tights", cost = 12, jobs = 'MNK/THF/RNG/NIN/BLU/COR/PUP/DNC/RUN' })  -- ilvl 100
table.insert(b.shields, { id = 28659, name = "Camaraderie Shield", cost = 12, jobs = 'WAR/PLD/DRK' })  -- ilvl 109
table.insert(b.shields, { id = 28657, name = "Kaidate", cost = 12, jobs = 'WAR/THF/PLD/DRK/BST/SAM' })  -- ilvl 109
table.insert(b.shields, { id = 28658, name = "Sors Shield", cost = 12, jobs = 'WHM/BLM/RDM/PLD/DRK/SMN/BLU/SCH/GEO/RUN' })  -- ilvl 109
table.insert(b.shields, { id = 28660, name = "Huactzin Shield", cost = 12, jobs = 'WAR/PLD/DRK' })  -- ilvl 106
table.insert(b.shields, { id = 28666, name = "Coalition Shield", cost = 12, jobs = 'WAR/PLD/DRK' })  -- ilvl 100
table.insert(s.body, { id = 27915, name = "Gendewitha Bliaut", cost = 25, jobs = 'WHM/RDM/BRD/SCH' })  -- ilvl 113
table.insert(s.body, { id = 27916, name = "Hagondes Coat", cost = 25, jobs = 'BLM/RDM/SMN/BLU/SCH/GEO' })  -- ilvl 113
table.insert(s.body, { id = 27914, name = "Iuitl Vest", cost = 25, jobs = 'THF/BST/RNG/BLU/COR/DNC/RUN' })  -- ilvl 113
table.insert(s.body, { id = 27913, name = "Otronif Harness", cost = 25, jobs = 'MNK/SAM/NIN/PUP' })  -- ilvl 113
table.insert(s.body, { id = 27919, name = "Bokwus Robe", cost = 25, jobs = 'WHM/BLM/RDM/BRD/SMN/SCH/GEO' })  -- ilvl 110
table.insert(s.body, { id = 27918, name = "Manibozho Jerkin", cost = 25, jobs = 'MNK/THF/RNG/NIN/BLU/COR/PUP/DNC/RUN' })  -- ilvl 110
table.insert(s.body, { id = 27917, name = "Mikinaak Breastplate", cost = 25, jobs = 'WAR/PLD/DRK/BST/SAM/DRG' })  -- ilvl 110
table.insert(s.feet, { id = 28305, name = "Ejekamal Boots", cost = 25, jobs = 'WAR/PLD/DRK/BST/SAM/DRG' })  -- ilvl 115
table.insert(s.feet, { id = 28331, name = "Ukuxkaj Boots", cost = 25, jobs = 'WHM/BLM/RDM/BRD/SMN/SCH/GEO' })  -- ilvl 115
table.insert(s.feet, { id = 28335, name = "Gendewitha Galoshes", cost = 25, jobs = 'WHM/RDM/BRD/SCH' })  -- ilvl 113
table.insert(s.feet, { id = 28336, name = "Hagondes Sabots", cost = 25, jobs = 'BLM/RDM/SMN/BLU/SCH/GEO' })  -- ilvl 113
table.insert(s.feet, { id = 28334, name = "Iuitl Gaiters", cost = 25, jobs = 'THF/BST/RNG/BLU/COR/DNC/RUN' })  -- ilvl 113
table.insert(s.feet, { id = 28333, name = "Otronif Boots", cost = 25, jobs = 'MNK/SAM/NIN/PUP' })  -- ilvl 113
table.insert(s.feet, { id = 28340, name = "Bokwus Boots", cost = 25, jobs = 'WHM/BLM/RDM/BRD/SMN/SCH/GEO' })  -- ilvl 110
table.insert(s.feet, { id = 28339, name = "Manibozho Boots", cost = 25, jobs = 'MNK/THF/RNG/NIN/BLU/COR/PUP/DNC/RUN' })  -- ilvl 110
table.insert(s.feet, { id = 28338, name = "Mikinaak Greaves", cost = 25, jobs = 'WAR/PLD/DRK/BST/SAM/DRG' })  -- ilvl 110
table.insert(s.hands, { id = 28050, name = "Buremte Gloves", cost = 25, jobs = 'WAR/RDM/THF/PLD/DRK/BST/BRD/RNG/SAM/NIN/DRG/BLU/COR/DNC/RUN' })  -- ilvl 115
table.insert(s.hands, { id = 28028, name = "Otomi Gloves", cost = 25, jobs = 'WHM/BLM/RDM/BRD/SMN/SCH/GEO' })  -- ilvl 115
table.insert(s.hands, { id = 28051, name = "Cizin Mufflers", cost = 25, jobs = 'WAR/PLD/DRK/DRG' })  -- ilvl 113
table.insert(s.hands, { id = 28054, name = "Gendewitha Gages", cost = 25, jobs = 'WHM/RDM/BRD/SCH' })  -- ilvl 113
table.insert(s.hands, { id = 28055, name = "Hagondes Cuffs", cost = 25, jobs = 'BLM/RDM/SMN/BLU/SCH/GEO' })  -- ilvl 113
table.insert(s.hands, { id = 28053, name = "Iuitl Wristbands", cost = 25, jobs = 'THF/BST/RNG/BLU/COR/DNC/RUN' })  -- ilvl 113
table.insert(s.hands, { id = 28052, name = "Otronif Gloves", cost = 25, jobs = 'MNK/SAM/NIN/PUP' })  -- ilvl 113
table.insert(s.hands, { id = 28059, name = "Bokwus Gloves", cost = 25, jobs = 'WHM/BLM/RDM/BRD/SMN/SCH/GEO' })  -- ilvl 110
table.insert(s.hands, { id = 28058, name = "Manibozho Gloves", cost = 25, jobs = 'MNK/THF/RNG/NIN/BLU/COR/PUP/DNC/RUN' })  -- ilvl 110
table.insert(s.hands, { id = 28057, name = "Mikinaak Gauntlets", cost = 25, jobs = 'WAR/PLD/DRK/BST/SAM/DRG' })  -- ilvl 110
table.insert(s.head, { id = 27767, name = "Buremte Hat", cost = 25, jobs = 'WHM/BLM/RDM/BRD/SMN/SCH/GEO' })  -- ilvl 115
table.insert(s.head, { id = 27738, name = "Ejekamal Mask", cost = 25, jobs = 'MNK/THF/RNG/NIN/BLU/COR/PUP/DNC/RUN' })  -- ilvl 115
table.insert(s.head, { id = 27737, name = "Kaabnax Hat", cost = 25, jobs = 'WHM/BLM/RDM/BRD/SMN/SCH/GEO' })  -- ilvl 115
table.insert(s.head, { id = 27739, name = "Otomi Helm", cost = 25, jobs = 'WAR/PLD/DRK/BST/SAM/DRG' })  -- ilvl 115
table.insert(s.head, { id = 27736, name = "Quiahuiz Helm", cost = 25, jobs = 'WAR/PLD/DRK/BST/DRG' })  -- ilvl 115
table.insert(s.head, { id = 27766, name = "Ukuxkaj Cap", cost = 25, jobs = 'MNK/THF/RNG/NIN/BLU/COR/PUP/DNC/RUN' })  -- ilvl 115
table.insert(s.head, { id = 27771, name = "Gendewitha Caubeen", cost = 25, jobs = 'WHM/RDM/BRD/SCH' })  -- ilvl 113
table.insert(s.head, { id = 27772, name = "Hagondes Hat", cost = 25, jobs = 'BLM/RDM/SMN/BLU/SCH/GEO' })  -- ilvl 113
table.insert(s.head, { id = 27770, name = "Iuitl Headgear", cost = 25, jobs = 'THF/BST/RNG/BLU/COR/DNC/RUN' })  -- ilvl 113
table.insert(s.head, { id = 27769, name = "Otronif Mask", cost = 25, jobs = 'MNK/SAM/NIN/PUP' })  -- ilvl 113
table.insert(s.head, { id = 27778, name = "Bokwus Circlet", cost = 25, jobs = 'WHM/BLM/RDM/BRD/SMN/SCH/GEO' })  -- ilvl 110
table.insert(s.head, { id = 27777, name = "Manibozho Beret", cost = 25, jobs = 'MNK/THF/RNG/NIN/BLU/COR/PUP/DNC/RUN' })  -- ilvl 110
table.insert(s.head, { id = 27776, name = "Mikinaak Helm", cost = 25, jobs = 'WAR/PLD/DRK/BST/SAM/DRG' })  -- ilvl 110
table.insert(s.legs, { id = 28167, name = "Kaabnax Trousers", cost = 25, jobs = 'MNK/THF/RNG/NIN/BLU/COR/PUP/DNC/RUN' })  -- ilvl 115
table.insert(s.legs, { id = 28166, name = "Quiahuiz Trousers", cost = 25, jobs = 'MNK/THF/RNG/NIN/BLU/COR/PUP/DNC/RUN' })  -- ilvl 115
table.insert(s.legs, { id = 28195, name = "Gendewitha Spats", cost = 25, jobs = 'WHM/RDM/BRD/SCH' })  -- ilvl 113
table.insert(s.legs, { id = 28196, name = "Hagondes Pants", cost = 25, jobs = 'BLM/RDM/SMN/BLU/SCH/GEO' })  -- ilvl 113
table.insert(s.legs, { id = 28194, name = "Iuitl Tights", cost = 25, jobs = 'THF/BST/RNG/BLU/COR/DNC/RUN' })  -- ilvl 113
table.insert(s.legs, { id = 28193, name = "Otronif Brais", cost = 25, jobs = 'MNK/SAM/NIN/PUP' })  -- ilvl 113
table.insert(s.legs, { id = 28200, name = "Bokwus Slops", cost = 25, jobs = 'WHM/BLM/RDM/BRD/SMN/SCH/GEO' })  -- ilvl 110
table.insert(s.legs, { id = 28199, name = "Manibozho Brais", cost = 25, jobs = 'MNK/THF/RNG/NIN/BLU/COR/PUP/DNC/RUN' })  -- ilvl 110
table.insert(s.legs, { id = 28198, name = "Mikinaak Cuisses", cost = 25, jobs = 'WAR/PLD/DRK/BST/SAM/DRG' })  -- ilvl 110
table.insert(s.shields, { id = 28663, name = "Steadfast Shield", cost = 25, jobs = 'WAR/PLD/DRK' })  -- ilvl 113
table.insert(g.feet, { id = 28282, name = "Conduit Shoes +1", cost = 50, jobs = 'WHM/BLM/RDM/BRD/SMN/SCH/GEO' })  -- ilvl 118
table.insert(g.feet, { id = 28283, name = "Gigantes Boots +1", cost = 50, jobs = 'WAR/PLD/DRK/BST/SAM/DRG' })  -- ilvl 118
table.insert(g.feet, { id = 28281, name = "Rager Ledelsens +1", cost = 50, jobs = 'MNK/RDM/THF/BST/RNG/NIN/DRG/COR/PUP/DNC/RUN' })  -- ilvl 118
table.insert(g.feet, { id = 28284, name = "Scopuli Nails +1", cost = 50, jobs = 'MNK/THF/RNG/NIN/BLU/COR/DNC/RUN' })  -- ilvl 118
table.insert(g.hands, { id = 28005, name = "Alrunas Gloves +1", cost = 50, jobs = 'THF/RNG/COR' })  -- ilvl 118
table.insert(g.hands, { id = 28006, name = "Iuvenalis Mittens +1", cost = 50, jobs = 'WHM' })  -- ilvl 118
table.insert(g.hands, { id = 28004, name = "Medbs Gauntlets +1", cost = 50, jobs = 'WAR/PLD/DRK' })  -- ilvl 118
table.insert(g.hands, { id = 28007, name = "Nomkahpa Mittens +1", cost = 50, jobs = 'MNK/THF/BST/RNG/NIN/BLU/COR/PUP/DNC/RUN' })  -- ilvl 118
table.insert(g.hands, { id = 28001, name = "Sasuke Tekko +1", cost = 50, jobs = 'MNK/SAM/NIN' })  -- ilvl 118
table.insert(g.hands, { id = 28003, name = "Seraph Mittens +1", cost = 50, jobs = 'WHM/BLM/RDM/BRD/SMN/BLU/PUP/SCH/GEO' })  -- ilvl 118
table.insert(g.hands, { id = 28002, name = "Slither Gloves +1", cost = 50, jobs = 'MNK/THF/RNG/SAM/NIN/COR/PUP/DNC/RUN' })  -- ilvl 118
table.insert(g.hands, { id = 28000, name = "Thrift Gloves +1", cost = 50, jobs = 'WHM/BLM/RDM/BRD/SMN/SCH/GEO' })  -- ilvl 118
table.insert(g.head, { id = 26697, name = "Accord Hat +1", cost = 50, jobs = 'SMN' })  -- ilvl 118
table.insert(g.head, { id = 26698, name = "Chersos Helm +1", cost = 50, jobs = 'WAR/PLD' })  -- ilvl 118
table.insert(g.head, { id = 26695, name = "Fugacity Beret +1", cost = 50, jobs = 'MNK/WHM/RDM/THF/BST/BRD/RNG/SAM/NIN/BLU/COR/DNC/RUN' })  -- ilvl 118
table.insert(g.head, { id = 26700, name = "Gallian Helm +1", cost = 50, jobs = 'WAR/PLD/DRK/BST/SAM/NIN' })  -- ilvl 118
table.insert(g.head, { id = 26696, name = "Pixie Hairpin +1", cost = 50, jobs = 'All' })  -- ilvl 118
table.insert(g.head, { id = 26701, name = "Smilodon Mask +1", cost = 50, jobs = 'WAR/MNK/THF/BST/NIN/DNC/RUN' })  -- ilvl 118
table.insert(g.head, { id = 26699, name = "Theias Hairpin +1", cost = 50, jobs = 'All' })  -- ilvl 118
table.insert(g.legs, { id = 28144, name = "Adapas Slacks +1", cost = 50, jobs = 'WHM/BLM/RDM/BRD/SMN/GEO' })  -- ilvl 118
table.insert(g.legs, { id = 28146, name = "Hidalgo Slops +1", cost = 50, jobs = 'WHM/BLM/RDM/SMN/BLU' })  -- ilvl 118
table.insert(g.legs, { id = 28145, name = "Mirador Trousers +1", cost = 50, jobs = 'RNG/COR' })  -- ilvl 118
table.insert(g.legs, { id = 28143, name = "Wukongs Hakama +1", cost = 50, jobs = 'WAR/MNK/RNG/SAM/NIN' })  -- ilvl 118
table.insert(g.shields, { id = 27630, name = "Thuellaic Ecu +1", cost = 50, jobs = 'WAR/WHM/RDM/THF/PLD/BST/SAM' })  -- ilvl 118
table.insert(g.shields, { id = 27629, name = "Weathering Shield +1", cost = 50, jobs = 'PLD' })  -- ilvl 118

return catalog
